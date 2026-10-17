import 'dart:async';
import 'package:meow_client/core/network/https_latency_probe.dart'
    show validateProbeUrl;

/// Adapter for SingboxRuntime.fetchUrlViaOutbound; deliberately avoids importing
/// the runtime so this controller remains independently testable.
typedef OutboundUrlFetch =
    Future<Map<String, dynamic>> Function({
      required String outboundTag,
      required Uri uri,
      required Map<String, String> headers,
      required int maxBytes,
      required Duration timeout,
    });

class RealUrlLatencyResult {
  const RealUrlLatencyResult({this.delayMs, this.error});
  final int? delayMs;
  final String? error;
}

/// Runs bounded, cancellable UI latency checks through a caller-provided fetch.
class RealUrlLatencyController {
  RealUrlLatencyController({required OutboundUrlFetch fetch}) : _fetch = fetch;
  final OutboundUrlFetch _fetch;

  static const int maxResponseBytes = 64 * 1024;
  static const Map<String, String> requestHeaders = {
    'Accept-Encoding': 'identity',
    'Cache-Control': 'no-cache',
  };

  final Map<String, RealUrlLatencyResult> results = {};
  final Set<String> _checking = {};
  int completed = 0;
  int total = 0;
  int _generation = 0;
  bool _running = false;

  bool get isRunning => _running;
  bool isChecking(String tag) => _checking.contains(tag.trim());

  Future<void> run(
    Iterable<String> tags,
    String url,
    Duration timeout,
    int concurrency,
    void Function() onChanged,
  ) async {
    final generation = ++_generation;
    _running = true;
    _checking.clear();
    completed = 0;
    total = 0;

    Uri? uri;
    String? validationError;
    try {
      uri = validateProbeUrl(url);
    } on Object {
      validationError = 'invalid_url';
    }
    final timeoutMs = timeout.inMilliseconds.clamp(1000, 30000);
    final boundedTimeout = Duration(milliseconds: timeoutMs);
    final workers = concurrency.clamp(1, 10);
    final uniqueTags = <String>[];
    final seen = <String>{};
    for (final raw in tags) {
      final tag = raw.trim();
      if (tag.isNotEmpty && seen.add(tag)) uniqueTags.add(tag);
    }
    for (final tag in uniqueTags) {
      results.remove(tag);
    }
    total = uniqueTags.length;
    _checking.addAll(uniqueTags);
    if (uniqueTags.isEmpty) {
      _running = false;
      onChanged();
      return;
    }
    onChanged();

    var cursor = 0;
    Future<void> worker() async {
      while (true) {
        if (generation != _generation) return;
        final index = cursor++;
        if (index >= uniqueTags.length) return;
        final tag = uniqueTags[index];
        final stopwatch = Stopwatch()..start();
        RealUrlLatencyResult result;
        if (validationError != null) {
          result = const RealUrlLatencyResult(error: 'invalid_url');
        } else {
          try {
            final response = await _fetch(
              outboundTag: tag,
              uri: uri!,
              headers: requestHeaders,
              maxBytes: maxResponseBytes,
              timeout: boundedTimeout,
            ).timeout(boundedTimeout);
            stopwatch.stop();
            if (generation != _generation) return;
            final status = _intValue(
              response['statusCode'] ?? response['status'],
            );
            final finalUrl = response['finalUrl'] ?? response['url'];
            final validFinalUrl = finalUrl is String && _isHttps(finalUrl);
            result =
                status != null && status >= 200 && status < 300 && validFinalUrl
                ? RealUrlLatencyResult(
                    delayMs: stopwatch.elapsedMilliseconds < 1
                        ? 1
                        : stopwatch.elapsedMilliseconds,
                  )
                : RealUrlLatencyResult(
                    error: status == null ? 'invalid_response' : 'http_error',
                  );
          } on TimeoutException {
            stopwatch.stop();
            result = const RealUrlLatencyResult(error: 'timeout');
          } on Object {
            stopwatch.stop();
            result = const RealUrlLatencyResult(error: 'transport_error');
          }
        }
        if (generation != _generation) return;
        results[tag] = result;
        _checking.remove(tag);
        completed++;
        onChanged();
      }
    }

    await Future.wait(List.generate(workers, (_) => worker()));
    if (generation == _generation) {
      _checking.clear();
      _running = false;
      onChanged();
    }
  }

  void cancel() {
    ++_generation;
    _running = false;
    _checking.clear();
  }

  void clear() {
    ++_generation;
    _running = false;
    _checking.clear();
    results.clear();
    completed = 0;
    total = 0;
  }

  static int? _intValue(Object? value) =>
      value is int ? value : int.tryParse('$value');
  static bool _isHttps(String value) {
    try {
      return Uri.parse(value).scheme == 'https' &&
          Uri.parse(value).host.isNotEmpty;
    } on FormatException {
      return false;
    }
  }
}
