import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meow_client/models/public_ip_source.dart';
import 'package:meow_client/singbox/singbox_api.g.dart' as pigeon;
import 'package:meow_client/singbox/singbox_runtime.dart';

export 'package:meow_client/models/public_ip_source.dart';

@immutable
class PublicIpQueryIdentity {
  const PublicIpQueryIdentity({
    required this.planId,
    required this.coreGeneration,
    required this.outboundTag,
    required this.networkGeneration,
    required this.source,
  });
  final String planId;
  final String coreGeneration;
  final String outboundTag;
  final int networkGeneration;
  final PublicIpSource source;
}

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
    this.identity,
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
  final PublicIpQueryIdentity? identity;

  PublicIpInfo withIdentity(PublicIpQueryIdentity identity) => PublicIpInfo(
    ip: ip,
    countryCode: countryCode,
    country: country,
    city: city,
    region: region,
    organization: organization,
    asn: asn,
    isp: isp,
    source: source,
    identity: identity,
  );

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

typedef PublicIpCoreLookup =
    Future<pigeon.PublicIpLookupResponseMessage> Function(
      pigeon.PublicIpLookupRequestMessage request,
    );
typedef PublicIpCoreCancel = Future<void> Function(String requestId);

/// All provider traffic is performed by the running core over its selected
/// outbound. No direct-network fallback is permitted.
class PublicIpLookup {
  PublicIpLookup({PublicIpCoreLookup? lookup, PublicIpCoreCancel? cancel})
    : _lookup = lookup ?? _runtimeLookup,
      _cancelRpc = cancel ?? _runtimeCancel;
  static Future<pigeon.PublicIpLookupResponseMessage> _runtimeLookup(
    pigeon.PublicIpLookupRequestMessage request,
  ) => SingboxRuntime.instance.lookupPublicIp(request);
  static Future<void> _runtimeCancel(String requestId) =>
      SingboxRuntime.instance.cancelPublicIp(requestId);
  final PublicIpCoreLookup _lookup;
  final PublicIpCoreCancel _cancelRpc;
  String? _activeRequestId;
  int _sequence = 0;
  Future<PublicIpInfo> load({
    PublicIpSource source = PublicIpSource.ipQuery,
    String outboundTag = '',
    int networkGeneration = 0,
  }) async {
    if (outboundTag.trim().isEmpty) {
      throw StateError('Public IP lookup requires a selected outbound');
    }
    cancel();
    final id =
        'public-ip-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';
    _activeRequestId = id;
    final response =
        await _lookup(
          pigeon.PublicIpLookupRequestMessage(
            requestId: id,
            outboundTag: outboundTag,
            provider: source.name,
            networkGeneration: networkGeneration,
            timeoutMillis: 10000,
          ),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (_activeRequestId == id) cancel();
            throw TimeoutException('Public IP whole-query deadline exceeded');
          },
        );
    if (_activeRequestId != id) throw StateError('IP request cancelled');
    if (response.outboundTag != outboundTag ||
        response.networkGeneration != networkGeneration ||
        response.planId.trim().isEmpty ||
        response.coreGeneration.trim().isEmpty) {
      throw StateError('Public IP response identity is stale or incomplete');
    }
    final decoded = jsonDecode(response.json);
    if (decoded is! Map) {
      throw const FormatException('Invalid public IP JSON response');
    }
    final json = Map<String, dynamic>.from(decoded);
    _activeRequestId = null;
    final info = switch (source) {
      PublicIpSource.ipQuery => PublicIpInfo.fromIpQueryJson(json),
      PublicIpSource.ipApi => PublicIpInfo.fromIpApiJson(json),
      PublicIpSource.ipWho => PublicIpInfo.fromIpWhoJson(json),
    };
    return info.withIdentity(
      PublicIpQueryIdentity(
        planId: response.planId,
        coreGeneration: response.coreGeneration,
        outboundTag: outboundTag,
        networkGeneration: networkGeneration,
        source: source,
      ),
    );
  }

  void cancel() {
    final id = _activeRequestId;
    _activeRequestId = null;
    if (id != null) unawaited(_cancelRpc(id).catchError((Object _) {}));
  }
}

/// App-owned: memory-only result and cooldown survive closing the sheet.
enum PublicIpFailureKind {
  unsupportedConfiguration,
  notConnected,
  timeout,
  general,
}

class PublicIpController extends ChangeNotifier {
  PublicIpController({
    Future<PublicIpInfo> Function()? load,
    VoidCallback? cancel,
    PublicIpSource Function()? sourceProvider,
    String Function()? outboundProvider,
    int Function()? networkGenerationProvider,
    Object Function()? scopeProvider,
    bool Function()? connectedProvider,
  }) {
    _connectedProvider = connectedProvider;
    _scope = () => (
      sourceProvider?.call() ?? PublicIpSource.ipQuery,
      outboundProvider?.call() ?? '',
      networkGenerationProvider?.call() ?? 0,
      scopeProvider?.call(),
    );
    _observedScope = _scope();
    if (load == null) {
      final lookup = PublicIpLookup();
      _load = () => lookup.load(
        source: sourceProvider?.call() ?? PublicIpSource.ipQuery,
        outboundTag: outboundProvider?.call() ?? '',
        networkGeneration: networkGenerationProvider?.call() ?? 0,
      );
      _cancel = lookup.cancel;
    } else {
      _load = load;
      _cancel = cancel ?? () {};
    }
  }

  late final Future<PublicIpInfo> Function() _load;
  late final VoidCallback _cancel;
  late final Object Function() _scope;
  late Object _observedScope;
  Object? _cachedScope;
  PublicIpInfo? _info;
  bool _loading = false;
  bool _failed = false;
  PublicIpFailureKind? _failureKind;
  late final bool Function()? _connectedProvider;
  bool _disposed = false;
  Timer? _cooldown;
  int _generation = 0;

  PublicIpInfo? get info => _cachedScope == _scope() ? _info : null;
  bool get loading => _loading;
  bool get failed => _failed;
  PublicIpFailureKind? get failureKind => _failureKind;
  bool get canRefresh => !_disposed && !_loading && _cooldown == null;

  /// Repeated group/traffic snapshots do not cancel a query unless its actual
  /// provider/outbound/config/core/network identity changed.
  void synchronizeScope() {
    if (!_disposed && _observedScope != _scope()) invalidateForSourceChange();
  }

  Future<void> refresh() async {
    synchronizeScope();
    if (!canRefresh) return;
    final scope = _scope();
    final generation = ++_generation;
    _loading = true;
    _failed = false;
    _failureKind = null;
    _cooldown = Timer(const Duration(seconds: 4), () {
      _cooldown = null;
      if (!_disposed) notifyListeners();
    });
    notifyListeners();
    try {
      final result = await _load();
      if (_disposed || generation != _generation) return;
      if (scope != _scope()) {
        invalidateForSourceChange();
        return;
      }
      _info = result;
      _cachedScope = scope;
    } catch (error) {
      if (_disposed || generation != _generation) return;
      if (scope != _scope()) {
        invalidateForSourceChange();
        return;
      }
      _failed = true;
      _failureKind = _classifyPublicIpFailure(
        error,
        connected: _connectedProvider?.call(),
      );
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
    _observedScope = _scope();
    _cachedScope = null;
    _generation++;
    _cancel();
    _cooldown?.cancel();
    _cooldown = null;
    _info = null;
    _loading = false;
    _failed = false;
    _failureKind = null;
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

PublicIpFailureKind _classifyPublicIpFailure(Object error, {bool? connected}) {
  if (connected == false) return PublicIpFailureKind.notConnected;
  if (error is TimeoutException) return PublicIpFailureKind.timeout;
  // Inspect only for categorization. The exception text is never presented.
  final message = error.toString().toLowerCase();
  if (message.contains('unsupported') ||
      message.contains('not supported') ||
      message.contains('invalid configuration') ||
      message.contains('unsupported configuration')) {
    return PublicIpFailureKind.unsupportedConfiguration;
  }
  if (message.contains('not connected') ||
      message.contains('requires a running') ||
      message.contains('no active connection') ||
      message.contains('disconnected')) {
    return PublicIpFailureKind.notConnected;
  }
  if (message.contains('timeout') || message.contains('timed out')) {
    return PublicIpFailureKind.timeout;
  }
  return PublicIpFailureKind.general;
}
