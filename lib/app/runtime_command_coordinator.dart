import 'dart:async';

import 'package:meow_client/logging/runtime_diagnostic_log.dart';

typedef SelectOutboundCommand =
    Future<void> Function(String groupTag, String outboundTag);

enum RuntimeSelectionStatus { applied, stale, failed }

class RuntimeSelectionResult {
  const RuntimeSelectionResult._(this.status, this.elapsed, [this.error]);

  final RuntimeSelectionStatus status;
  final Duration elapsed;
  final Object? error;

  bool get applied => status == RuntimeSelectionStatus.applied;
}

/// Owns control-command policy for the single libbox runtime.
///
/// A timed-out native RPC can still finish later, so selector commands are
/// never retried automatically. Retrying would enqueue the same mutation
/// twice and used to trigger restart races with URLTest.
class RuntimeCommandCoordinator {
  RuntimeCommandCoordinator({
    required SelectOutboundCommand selectOutbound,
    this.selectionTimeout = const Duration(seconds: 20),
  }) : _selectOutbound = selectOutbound;

  final SelectOutboundCommand _selectOutbound;
  final Duration selectionTimeout;

  int _generation = 0;
  bool _disposed = false;

  void invalidate() {
    _generation++;
  }

  Future<RuntimeSelectionResult> selectOutbound(String outboundTag) async {
    final normalizedTag = outboundTag.trim();
    final generation = ++_generation;
    final stopwatch = Stopwatch()..start();
    RuntimeDiagnosticLog.record(
      'proxy.selection.runtime',
      fields: {'phase': 'begin', 'selectedPresent': normalizedTag.isNotEmpty},
    );
    if (_disposed || normalizedTag.isEmpty) {
      stopwatch.stop();
      RuntimeDiagnosticLog.record(
        'proxy.selection.runtime',
        fields: {
          'phase': 'complete',
          'result': 'stale',
          'durationMs': stopwatch.elapsedMilliseconds,
        },
        level: RuntimeDiagnosticLevel.warning,
      );
      return RuntimeSelectionResult._(
        RuntimeSelectionStatus.stale,
        stopwatch.elapsed,
      );
    }

    try {
      await _selectOutbound('select', normalizedTag).timeout(selectionTimeout);
      stopwatch.stop();
      if (_disposed || generation != _generation) {
        RuntimeDiagnosticLog.record(
          'proxy.selection.runtime',
          fields: {
            'phase': 'complete',
            'result': 'stale',
            'durationMs': stopwatch.elapsedMilliseconds,
          },
          level: RuntimeDiagnosticLevel.warning,
        );
        return RuntimeSelectionResult._(
          RuntimeSelectionStatus.stale,
          stopwatch.elapsed,
        );
      }
      RuntimeDiagnosticLog.record(
        'proxy.selection.runtime',
        fields: {
          'phase': 'complete',
          'result': 'success',
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );
      return RuntimeSelectionResult._(
        RuntimeSelectionStatus.applied,
        stopwatch.elapsed,
      );
    } catch (error) {
      stopwatch.stop();
      final stale = _disposed || generation != _generation;
      RuntimeDiagnosticLog.record(
        'proxy.selection.runtime',
        fields: {
          'phase': 'complete',
          'result': stale ? 'stale' : 'failed',
          'durationMs': stopwatch.elapsedMilliseconds,
          ...RuntimeDiagnosticLog.errorFields(error),
        },
        level: RuntimeDiagnosticLevel.error,
      );
      if (stale) {
        return RuntimeSelectionResult._(
          RuntimeSelectionStatus.stale,
          stopwatch.elapsed,
          error,
        );
      }
      return RuntimeSelectionResult._(
        RuntimeSelectionStatus.failed,
        stopwatch.elapsed,
        error,
      );
    }
  }

  void dispose() {
    _disposed = true;
    invalidate();
  }
}
