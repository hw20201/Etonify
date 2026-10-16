import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:meow_client/models/public_ip_source.dart';

export 'package:meow_client/models/public_ip_source.dart';

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
  final PublicIpSource source;

  String get locationLabel {
    final countryLabel = country.isNotEmpty ? country : countryCode;
    final places = <String>[];
    for (final place in [region, city]) {
      if (place.isNotEmpty &&
          !places.any(
            (existing) => existing.toLowerCase() == place.toLowerCase(),
          )) {
        places.add(place);
      }
    }
    return [if (countryLabel.isNotEmpty) countryLabel, ...places].join(' · ');
  }

  factory PublicIpInfo.fromIpQueryJson(Map<String, dynamic> json) {
    final ip = _validatedIp(json['ip']);
    final isp = _asMap(json['isp']);
    final location = _asMap(json['location']);
    return PublicIpInfo(
      ip: ip,
      countryCode: _countryCode(location['country_code']),
      country: _text(location['country']),
      city: _text(location['city']),
      region: _text(location['state']),
      organization: _text(isp['org']),
      asn: _normalizeAsn(isp['asn']),
      isp: _text(isp['isp']),
      source: PublicIpSource.ipQuery,
    );
  }

  factory PublicIpInfo.fromIpApiJson(Map<String, dynamic> json) {
    if (json['status'] != 'success') {
      throw const FormatException('IP-API lookup was not successful');
    }
    return PublicIpInfo(
      ip: _validatedIp(json['query']),
      countryCode: _countryCode(json['countryCode']),
      country: _text(json['country']),
      city: _text(json['city']),
      region: _text(json['regionName']),
      organization: _text(json['org']),
      asn: _normalizeAsn(json['as']),
      isp: _text(json['isp']),
      source: PublicIpSource.ipApi,
    );
  }

  factory PublicIpInfo.fromIpWhoJson(Map<String, dynamic> json) {
    if (json['success'] == false) {
      final message = _text(json['message']);
      throw FormatException(
        message.isEmpty ? 'ipwho.is lookup was not successful' : message,
      );
    }
    final connection = _asMap(json['connection']);
    return PublicIpInfo(
      ip: _validatedIp(json['ip']),
      countryCode: _countryCode(json['country_code']),
      country: _text(json['country']),
      city: _text(json['city']),
      region: _text(json['region']),
      organization: _text(connection['org']),
      asn: _normalizeAsn(connection['asn']),
      isp: _text(connection['isp']),
      source: PublicIpSource.ipWho,
    );
  }
}

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

String _normalizeAsn(Object? value) {
  if (value is num) {
    return value > 0 ? 'AS${value.toInt()}' : '';
  }
  final text = _text(value);
  if (text.isEmpty) return '';
  final token = RegExp(
    r'^(?:AS)?\d+\b',
    caseSensitive: false,
  ).firstMatch(text)?.group(0);
  if (token == null) return text;
  final normalized = token.toUpperCase();
  return normalized.startsWith('AS') ? normalized : 'AS$normalized';
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

/// Queries exactly the selected provider so the chosen destination is explicit
/// and a failed provider never silently sends the user's IP to another service.
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

  Future<PublicIpInfo> load({
    PublicIpSource source = PublicIpSource.ipQuery,
  }) async {
    final generation = ++_generation;
    late final Uri uri;
    late final String host;
    late final String accept;
    var observeIpApiRateLimit = false;

    switch (source) {
      case PublicIpSource.ipQuery:
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
        final result = PublicIpInfo.fromIpQueryJson(
          _decodeJson(detailsPayload.body),
        );
        if (generation != _generation) throw StateError('IP request cancelled');
        return result;
      case PublicIpSource.ipApi:
        final blockedUntil = _ipApiBlockedUntil;
        if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) {
          throw HttpException(
            'ip-api.com rate limited; try again after ${blockedUntil.toIso8601String()}',
          );
        }
        uri = Uri.http('ip-api.com', '/json/', const {
          'fields':
              'status,message,query,country,countryCode,regionName,city,isp,org,as',
        });
        host = 'ip-api.com';
        accept = 'application/json';
        observeIpApiRateLimit = true;
        break;
      case PublicIpSource.ipWho:
        uri = Uri.https('ipwho.is', '/');
        host = 'ipwho.is';
        accept = 'application/json';
        break;
    }

    final payload = await _request(
      uri,
      generation,
      accept: accept,
      observeIpApiRateLimit: observeIpApiRateLimit,
    );
    _requireOk(payload, host);
    final json = _decodeJson(payload.body);
    final result = switch (source) {
      PublicIpSource.ipQuery => throw StateError('unreachable IP query path'),
      PublicIpSource.ipApi => PublicIpInfo.fromIpApiJson(json),
      PublicIpSource.ipWho => PublicIpInfo.fromIpWhoJson(json),
    };
    if (generation != _generation) throw StateError('IP request cancelled');
    return result;
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
    PublicIpSource Function()? sourceProvider,
  }) {
    if (load == null) {
      final lookup = PublicIpLookup();
      _load = () =>
          lookup.load(source: sourceProvider?.call() ?? PublicIpSource.ipQuery);
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

  /// Discards data from the old provider and makes the new source immediately
  /// refreshable, including when a previous lookup is still in flight.
  void invalidateForSourceChange() {
    if (_disposed) return;
    _generation++;
    _cancel();
    _cooldown?.cancel();
    _cooldown = null;
    _info = null;
    _loading = false;
    _failed = false;
    notifyListeners();
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
