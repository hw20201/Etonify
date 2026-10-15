import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class PublicIpInfo {
  const PublicIpInfo({
    required this.ip,
    this.countryCode = '',
    this.country = '',
    this.city = '',
    this.region = '',
    this.organization = '',
    this.asn = '',
    this.isp = '',
    this.riskScore,
    this.isMobile = false,
    this.isVpn = false,
    this.isTor = false,
    this.isProxy = false,
    this.isDatacenter = false,
    this.source = PublicIpSource.ipQuery,
  });

  final String ip;
  final String countryCode;
  final String country;
  final String city;
  final String region;
  final String organization;
  final String asn;
  final String isp;
  final int? riskScore;
  final bool isMobile;
  final bool isVpn;
  final bool isTor;
  final bool isProxy;
  final bool isDatacenter;
  final PublicIpSource source;

  PublicIpNetworkType get networkType {
    if (isTor) return PublicIpNetworkType.tor;
    if (isVpn) return PublicIpNetworkType.vpn;
    if (isProxy) return PublicIpNetworkType.proxy;
    if (isDatacenter) return PublicIpNetworkType.datacenter;
    if (isMobile) return PublicIpNetworkType.mobile;
    return PublicIpNetworkType.regular;
  }

  factory PublicIpInfo.fromIpQueryJson(Map<String, dynamic> json) {
    final ip = _validatedIp(json['ip']);
    final isp = _asMap(json['isp']);
    final location = _asMap(json['location']);
    final risk = _asMap(json['risk']);
    final score = risk['risk_score'];
    return PublicIpInfo(
      ip: ip,
      countryCode: _countryCode(location['country_code']),
      country: _text(location['country']),
      city: _text(location['city']),
      region: _text(location['state']),
      organization: _text(isp['org']),
      asn: _text(isp['asn']),
      isp: _text(isp['isp']),
      riskScore: score is num && score >= 0 && score <= 100
          ? score.toInt()
          : null,
      isMobile: risk['is_mobile'] == true,
      isVpn: risk['is_vpn'] == true,
      isTor: risk['is_tor'] == true,
      isProxy: risk['is_proxy'] == true,
      isDatacenter: risk['is_datacenter'] == true,
      source: PublicIpSource.ipQuery,
    );
  }

  factory PublicIpInfo.fromIpApiJson(Map<String, dynamic> json) {
    if (json['status'] != 'success') {
      throw const FormatException('IP-API lookup was not successful');
    }
    final asValue = _text(json['as']);
    final asn =
        RegExp(
          r'^(AS\d+)\b',
          caseSensitive: false,
        ).firstMatch(asValue)?.group(1) ??
        '';
    return PublicIpInfo(
      ip: _validatedIp(json['query']),
      countryCode: _countryCode(json['countryCode']),
      country: _text(json['country']),
      city: _text(json['city']),
      region: _text(json['regionName']),
      organization: _text(json['org']),
      asn: asn,
      isp: _text(json['isp']),
      isMobile: json['mobile'] == true,
      isProxy: json['proxy'] == true,
      isDatacenter: json['hosting'] == true,
      source: PublicIpSource.ipApi,
    );
  }
}

enum PublicIpSource { ipQuery, ipApi }

enum PublicIpNetworkType { regular, mobile, vpn, tor, proxy, datacenter }

String _text(Object? value) => value is String ? value.trim() : '';

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const <String, dynamic>{};
}

String _countryCode(Object? value) {
  final code = _text(value).toUpperCase();
  return RegExp(r'^[A-Z]{2}$').hasMatch(code) && code != 'XX' ? code : '';
}

String _validatedIp(Object? value) {
  final ip = _text(value);
  if (InternetAddress.tryParse(ip) == null) {
    throw const FormatException('Invalid public IP response');
  }
  return ip;
}

class _HttpPayload {
  const _HttpPayload(this.statusCode, this.headers, this.body);

  final int statusCode;
  final Map<String, String> headers;
  final String body;
}

/// Queries the public egress IP through the normal OS network route.
///
/// ipquery.io is the HTTPS primary. ip-api.com is a last-resort HTTP-only
/// fallback, so Android cleartext access is limited to that exact host.
class PublicIpLookup {
  PublicIpLookup({http.Client Function()? clientFactory})
    : _clientFactory = clientFactory ?? http.Client.new;

  static const _requestTimeout = Duration(seconds: 3);
  static const _maxResponseBytes = 16 * 1024;
  static const _ipApiBlockedDefault = Duration(seconds: 60);

  final http.Client Function() _clientFactory;
  http.Client? _client;
  int _generation = 0;
  DateTime? _ipApiBlockedUntil;

  Future<PublicIpInfo> load() async {
    final generation = ++_generation;
    Object? primaryError;

    try {
      final ipPayload = await _request(
        Uri.https('api.ipquery.io', '/'),
        generation,
        accept: 'text/plain',
      );
      _requireOk(ipPayload, 'ipquery.io');
      final ip = _validatedIp(ipPayload.body);
      final detailsPayload = await _request(
        Uri.https('api.ipquery.io', '/$ip', {'format': 'json'}),
        generation,
        accept: 'application/json',
      );
      _requireOk(detailsPayload, 'ipquery.io');
      final json = _decodeJson(detailsPayload.body);
      final result = PublicIpInfo.fromIpQueryJson(json);
      if (generation != _generation) throw StateError('IP request cancelled');
      return result;
    } catch (error) {
      if (generation != _generation) throw StateError('IP request cancelled');
      primaryError = error;
    }

    final blockedUntil = _ipApiBlockedUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) {
      throw primaryError;
    }

    try {
      final fallbackPayload = await _request(
        Uri.http('ip-api.com', '/json/', const {
          'fields':
              'status,message,query,country,countryCode,regionName,city,isp,org,as,mobile,proxy,hosting',
        }),
        generation,
        accept: 'application/json',
        observeIpApiRateLimit: true,
      );
      _requireOk(fallbackPayload, 'ip-api.com');
      final json = _decodeJson(fallbackPayload.body);
      final result = PublicIpInfo.fromIpApiJson(json);
      if (generation != _generation) throw StateError('IP request cancelled');
      return result;
    } catch (error) {
      if (generation != _generation) throw StateError('IP request cancelled');
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  Future<_HttpPayload> _request(
    Uri uri,
    int generation, {
    required String accept,
    bool observeIpApiRateLimit = false,
  }) async {
    if (generation != _generation) throw StateError('IP request cancelled');
    final client = _clientFactory();
    _client = client;
    try {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['Accept'] = accept
        ..headers['Cache-Control'] = 'no-cache';
      final response = await client.send(request).timeout(_requestTimeout);
      if (observeIpApiRateLimit) _observeIpApiRateLimit(response);
      final bytes = BytesBuilder(copy: false);
      if ((response.contentLength ?? 0) > _maxResponseBytes) {
        throw const FormatException('Public IP response too large');
      }
      await for (final chunk in response.stream.timeout(_requestTimeout)) {
        if (bytes.length + chunk.length > _maxResponseBytes) {
          throw const FormatException('Public IP response too large');
        }
        bytes.add(chunk);
      }
      if (generation != _generation) throw StateError('IP request cancelled');
      return _HttpPayload(
        response.statusCode,
        response.headers,
        utf8.decode(bytes.takeBytes()),
      );
    } on TimeoutException {
      client.close();
      rethrow;
    } finally {
      client.close();
      if (identical(_client, client)) _client = null;
    }
  }

  void _observeIpApiRateLimit(http.StreamedResponse response) {
    final headers = response.headers;
    final remaining = int.tryParse(headers['x-rl'] ?? '');
    if (response.statusCode != HttpStatus.tooManyRequests && remaining != 0) {
      return;
    }
    final ttlSeconds = int.tryParse(headers['x-ttl'] ?? '');
    final ttl = ttlSeconds == null || ttlSeconds < 1
        ? _ipApiBlockedDefault
        : Duration(seconds: math.min(ttlSeconds, 24 * 60 * 60));
    _ipApiBlockedUntil = DateTime.now().add(ttl);
  }

  void _requireOk(_HttpPayload response, String host) {
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('$host HTTP ${response.statusCode}');
    }
  }

  Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
    throw const FormatException('Invalid public IP JSON response');
  }

  void cancel() {
    _generation++;
    _client?.close();
    _client = null;
  }
}

/// App-owned: memory-only result and cooldown survive closing the sheet.
class PublicIpController extends ChangeNotifier {
  PublicIpController({
    Future<PublicIpInfo> Function()? load,
    VoidCallback? cancel,
  }) {
    if (load == null) {
      final lookup = PublicIpLookup();
      _load = lookup.load;
      _cancel = lookup.cancel;
    } else {
      _load = load;
      _cancel = cancel ?? () {};
    }
  }

  late final Future<PublicIpInfo> Function() _load;
  late final VoidCallback _cancel;
  PublicIpInfo? _info;
  bool _loading = false;
  bool _failed = false;
  bool _disposed = false;
  Timer? _cooldown;
  int _generation = 0;

  PublicIpInfo? get info => _info;
  bool get loading => _loading;
  bool get failed => _failed;
  bool get canRefresh => !_disposed && !_loading && _cooldown == null;

  Future<void> refresh() async {
    if (!canRefresh) return;
    final generation = ++_generation;
    _loading = true;
    _failed = false;
    _cooldown = Timer(const Duration(seconds: 4), () {
      _cooldown = null;
      if (!_disposed) notifyListeners();
    });
    notifyListeners();
    try {
      final result = await _load();
      if (_disposed || generation != _generation) return;
      _info = result;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _failed = true;
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void cancel() {
    if (_disposed) return;
    _generation++;
    _cancel();
    if (_loading) {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    cancel();
    _disposed = true;
    _cooldown?.cancel();
    super.dispose();
  }
}
