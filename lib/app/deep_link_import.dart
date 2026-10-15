import 'dart:async';

import 'package:flutter/services.dart';

enum DeepLinkImportSource { unknown, etonifyImport, singBoxRemoteProfile }

class DeepLinkImportRequest {
  const DeepLinkImportRequest({
    required this.url,
    this.name,
    this.scheme,
    this.sourceType = DeepLinkImportSource.unknown,
  });

  final String url;
  final String? name;
  final String? scheme;
  final DeepLinkImportSource sourceType;

  static DeepLinkImportRequest? fromPayload(Object? payload) {
    if (payload is! Map) {
      return null;
    }

    final rawUrl = payload['url'];
    if (rawUrl is! String) {
      return null;
    }
    final rawName = payload['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : null;
    final rawScheme = payload['scheme'];
    final scheme = rawScheme is String && rawScheme.trim().isNotEmpty
        ? rawScheme.trim()
        : null;
    final rawSourceType = payload['sourceType'];

    // This fork no longer handles Happ links, including Happ's wrapped HTTP
    // links whose payload itself only contains the resolved subscription URL.
    if (scheme?.toLowerCase() == 'happ' ||
        rawUrl.trim().toLowerCase().startsWith('happ:') ||
        (rawSourceType is String &&
            rawSourceType.trim().toLowerCase().startsWith('happ'))) {
      return null;
    }

    final sourceType =
        _parseSourceType(rawSourceType) ??
        _inferSourceType(rawUrl.trim(), scheme: scheme);
    final url = _normalizeImportUrl(rawUrl.trim());
    if (url == null) {
      return null;
    }

    return DeepLinkImportRequest(
      url: url,
      name: name,
      scheme: scheme,
      sourceType: sourceType,
    );
  }

  static String? _normalizeImportUrl(String rawUrl) {
    if (rawUrl.isEmpty) {
      return null;
    }
    return _normalizeSingBoxRemoteProfileUrl(rawUrl) ?? rawUrl;
  }

  static DeepLinkImportSource? _parseSourceType(Object? value) {
    if (value is! String) {
      return null;
    }
    return switch (value.trim()) {
      'etonifyImport' => DeepLinkImportSource.etonifyImport,
      'singBoxRemoteProfile' => DeepLinkImportSource.singBoxRemoteProfile,
      _ => null,
    };
  }

  static DeepLinkImportSource _inferSourceType(
    String rawUrl, {
    String? scheme,
  }) {
    final uri = Uri.tryParse(rawUrl);
    final rawScheme = uri?.scheme.toLowerCase() ?? '';
    final normalizedScheme = rawScheme == 'sing-box'
        ? rawScheme
        : (scheme ?? rawScheme).toLowerCase();
    if (normalizedScheme == 'sing-box') {
      return DeepLinkImportSource.singBoxRemoteProfile;
    }
    if (normalizedScheme == 'etonify' || normalizedScheme == 'meowvpn') {
      return DeepLinkImportSource.etonifyImport;
    }
    return DeepLinkImportSource.unknown;
  }

  static String? _normalizeSingBoxRemoteProfileUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme.toLowerCase() != 'sing-box') {
      return null;
    }
    final host = uri.host.toLowerCase();
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    if (host != 'import-remote-profile' &&
        path.toLowerCase() != 'import-remote-profile') {
      return null;
    }
    final url = uri.queryParameters['url']?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    return url;
  }
}

class DeepLinkImportBridge {
  DeepLinkImportBridge._();

  static const MethodChannel _methods = MethodChannel('meow_client/deep_links');
  static const EventChannel _events = EventChannel(
    'meow_client/deep_link_events',
  );

  static Stream<DeepLinkImportRequest> get stream async* {
    await for (final payload in _events.receiveBroadcastStream()) {
      final request = DeepLinkImportRequest.fromPayload(payload);
      if (request != null) {
        yield request;
      }
    }
  }

  static Future<DeepLinkImportRequest?> getInitialRequest() async {
    final payload = await _methods.invokeMethod<Object?>(
      'getInitialImportRequest',
    );
    return DeepLinkImportRequest.fromPayload(payload);
  }
}
