import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The normal Draft/Release build leaves this compile-time flag unset (false).
/// Enable only for a private diagnostic test build with
/// --dart-define=ETONIFY_RUNTIME_DIAGNOSTICS=true.
const bool runtimeDiagnosticsBuild = bool.fromEnvironment(
  'ETONIFY_RUNTIME_DIAGNOSTICS',
  defaultValue: false,
);

enum RuntimeDiagnosticLevel { info, warning, error }

class RuntimeDiagnosticEntry {
  const RuntimeDiagnosticEntry({
    required this.timestamp,
    required this.level,
    required this.event,
    required this.fields,
  });

  final DateTime timestamp;
  final RuntimeDiagnosticLevel level;
  final String event;
  final Map<String, Object> fields;

  String format() {
    final encodedFields = fields.isEmpty ? '' : ' ${jsonEncode(fields)}';
    return '[${timestamp.toIso8601String()}] '
        '${level.name.toUpperCase()} $event$encodedFields';
  }
}

/// A small in-memory ring buffer for structured, privacy-preserving events.
/// Values are restricted to numeric/boolean data or short allow-listed tokens.
class RuntimeDiagnosticBuffer {
  RuntimeDiagnosticBuffer({required this.enabled, this.maxEntries = 500})
    : entries = ValueNotifier<List<RuntimeDiagnosticEntry>>(const []);

  static const int maxFieldsPerEntry = 12;
  static const int maxAllowedEntries = 1000;
  static const int maxEntryCharacters = 2048;

  static const Set<String> _allowedFields = {
    'phase',
    'mode',
    'kind',
    'result',
    'reason',
    'cancelReason',
    'errorKind',
    'errorSummary',
    'errorType',
    'transport',
    'source',
    'durationMs',
    'rpcMs',
    'confirmationMs',
    'localUpdateMs',
    'persistenceMs',
    'latencyMs',
    'expectedCount',
    'receivedCount',
    'successfulCount',
    'nodeCount',
    'networkGeneration',
    'runtimeGeneration',
    'operationGeneration',
    'success',
    'connected',
    'usable',
    'physicalChanged',
    'selectedPresent',
  };

  static const Set<String> _numericFields = {
    'durationMs',
    'rpcMs',
    'confirmationMs',
    'localUpdateMs',
    'persistenceMs',
    'latencyMs',
    'expectedCount',
    'receivedCount',
    'successfulCount',
    'nodeCount',
    'networkGeneration',
    'runtimeGeneration',
    'operationGeneration',
  };

  static const Map<String, Set<String>> _safeTokens = {
    'phase': {
      'begin',
      'config_promotion',
      'native_rpc',
      'confirmation',
      'local_update',
      'persistence',
      'complete',
      'failed',
      'cancelled',
      'result',
      'observed',
    },
    'mode': {'vpn', 'proxy', 'full', 'targeted'},
    'kind': {'full', 'targeted', 'parallel'},
    'result': {
      'success',
      'failed',
      'timeout',
      'stale',
      'cancelled',
      'partial',
      'available',
      'unavailable',
      'skipped',
    },
    'reason': {
      'user_action',
      'network_changed',
      'network_unavailable',
      'runtime_stopped',
      'runtime_transition',
      'capability_changed',
      'manual',
      'automatic',
      'all_expected_results',
      'no_fresh_events',
      'native_command_timeout',
      'native_command_error',
      'cancelled',
      'startup_lease_expired',
      'hard_watchdog',
      'event_stream_settled',
      'stale_runtime',
      'not_ready',
      'already_running',
      'unsupported',
      'superseded',
      'disposed',
      'other',
    },
    'cancelReason': {
      'user_action',
      'network_changed',
      'network_unavailable',
      'runtime_stopped',
      'runtime_transition',
      'capability_changed',
      'automatic_cancelled',
      'disposed',
      'other',
    },
    'errorKind': {
      'timeout',
      'dns',
      'socket',
      'tls',
      'permission',
      'platform',
      'cancelled',
      'other',
    },
    'errorSummary': {
      'timeout',
      'dns_lookup_failed',
      'connection_reset',
      'connection_refused',
      'no_route',
      'tls_handshake_failed',
      'permission_denied',
      'cancelled',
      'socket_error',
      'platform_error',
      'unclassified_error',
    },
    'transport': {'wifi', 'cellular', 'ethernet', 'vpn', 'other', 'unknown'},
    'source': {'user', 'system', 'manual', 'automatic', 'network'},
  };

  final bool enabled;
  final int maxEntries;
  final ValueNotifier<List<RuntimeDiagnosticEntry>> entries;

  void record(
    String event, {
    Map<String, Object?> fields = const {},
    RuntimeDiagnosticLevel level = RuntimeDiagnosticLevel.info,
  }) {
    if (!enabled || !_isSafeEventName(event)) return;

    final safeFields = <String, Object>{};
    for (final entry in fields.entries.take(maxFieldsPerEntry)) {
      if (!_allowedFields.contains(entry.key)) continue;
      final value = _sanitizeValue(entry.key, entry.value);
      if (value != null) safeFields[entry.key] = value;
    }
    final safeFieldsView = Map<String, Object>.unmodifiable(safeFields);
    final candidate = RuntimeDiagnosticEntry(
      timestamp: DateTime.now(),
      level: level,
      event: event,
      fields: safeFieldsView,
    );
    final line = candidate.format();
    if (line.length > maxEntryCharacters) return;

    final boundedLimit = maxEntries.clamp(1, maxAllowedEntries).toInt();
    final next = List<RuntimeDiagnosticEntry>.from(entries.value)
      ..add(candidate);
    if (next.length > boundedLimit) {
      next.removeRange(0, next.length - boundedLimit);
    }
    entries.value = List<RuntimeDiagnosticEntry>.unmodifiable(next);
  }

  void clear() {
    entries.value = const [];
  }

  String dump() => entries.value.map((entry) => entry.format()).join('\n');

  static bool _isSafeEventName(String value) {
    return value.length <= 96 &&
        RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){0,3}$').hasMatch(value);
  }

  static Object? _sanitizeValue(String key, Object? value) {
    if (_numericFields.contains(key) && value is num && value.isFinite) {
      return value.toInt().clamp(0, 1000000000);
    }
    if ({
          'success',
          'connected',
          'usable',
          'physicalChanged',
          'selectedPresent',
        }.contains(key) &&
        value is bool) {
      return value;
    }
    final tokens = _safeTokens[key];
    if (tokens != null && value is String) {
      return tokens.contains(value) ? value : 'other';
    }
    if (key == 'errorType' && value is String) {
      final type = value.trim();
      if (type.length <= 80 &&
          RegExp(r'^[A-Za-z][A-Za-z0-9_.]*$').hasMatch(type)) {
        return type;
      }
      return 'Error';
    }
    return null;
  }
}

class RuntimeDiagnosticLog {
  RuntimeDiagnosticLog._();

  static const bool enabled = runtimeDiagnosticsBuild;
  static final RuntimeDiagnosticBuffer _buffer = RuntimeDiagnosticBuffer(
    enabled: enabled,
  );

  static ValueListenable<List<RuntimeDiagnosticEntry>> get entries =>
      _buffer.entries;

  static void record(
    String event, {
    Map<String, Object?> fields = const {},
    RuntimeDiagnosticLevel level = RuntimeDiagnosticLevel.info,
  }) {
    _buffer.record(event, fields: fields, level: level);
  }

  static void clear() => _buffer.clear();

  static String dump() => _buffer.dump();

  /// Produces a small error summary without retaining the original error text,
  /// which can contain a host, address, node label, URL or credential.
  static Map<String, Object> errorFields(Object error) {
    final message = error.toString().toLowerCase();
    final String kind;
    final String summary;
    if (message.contains('failed host lookup') ||
        message.contains('no such host') ||
        message.contains('dns')) {
      kind = 'dns';
      summary = 'dns_lookup_failed';
    } else if (message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('deadline')) {
      kind = 'timeout';
      summary = 'timeout';
    } else if (message.contains('connection reset') ||
        message.contains('reset by peer')) {
      kind = 'socket';
      summary = 'connection_reset';
    } else if (message.contains('connection refused')) {
      kind = 'socket';
      summary = 'connection_refused';
    } else if (message.contains('no route')) {
      kind = 'socket';
      summary = 'no_route';
    } else if (message.contains('handshake') ||
        message.contains('certificate') ||
        message.contains('tls') ||
        message.contains('ssl')) {
      kind = 'tls';
      summary = 'tls_handshake_failed';
    } else if (message.contains('permission') ||
        message.contains('denied') ||
        message.contains('unauthorized')) {
      kind = 'permission';
      summary = 'permission_denied';
    } else if (message.contains('cancel')) {
      kind = 'cancelled';
      summary = 'cancelled';
    } else if (error.runtimeType.toString().contains('Platform')) {
      kind = 'platform';
      summary = 'platform_error';
    } else if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('i/o')) {
      kind = 'socket';
      summary = 'socket_error';
    } else {
      kind = 'other';
      summary = 'unclassified_error';
    }
    return {
      'errorKind': kind,
      'errorSummary': summary,
      'errorType': error.runtimeType.toString(),
    };
  }

  static String safeTransportForInterface(String? interfaceName) {
    final normalized = interfaceName?.trim().toLowerCase() ?? '';
    if (normalized.startsWith('wlan') || normalized.startsWith('wifi')) {
      return 'wifi';
    }
    if (normalized.startsWith('ccmni') ||
        normalized.startsWith('rmnet') ||
        normalized.startsWith('wwan') ||
        normalized.startsWith('pdp')) {
      return 'cellular';
    }
    if (normalized.startsWith('eth')) return 'ethernet';
    if (normalized.startsWith('tun')) return 'vpn';
    if (normalized.isEmpty) return 'unknown';
    return 'other';
  }
}
