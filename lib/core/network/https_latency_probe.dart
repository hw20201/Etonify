import 'dart:async';
import 'dart:io';

typedef ProbeClientFactory = HttpClient Function();

class ProbeSample {
  ProbeSample({
    required this.outcome,
    this.statusCode,
    this.bytes = 0,
    this.headerMs,
    this.bodyMs,
    this.reused,
  });
  final String outcome;
  final int? statusCode;
  final int bytes;
  final int? headerMs;
  final int? bodyMs;
  final bool? reused;
  _Connection? _connection;
  Map<String, Object?> toJson() => {
    'outcome': outcome,
    'statusCode': statusCode,
    'bytes': bytes,
    'headerMs': headerMs,
    'bodyMs': bodyMs,
    'verifiedReused': reused,
  };
}

class ProbePair {
  ProbePair(this.first, this.second);
  final ProbeSample first;
  final ProbeSample second;
  Map<String, Object?> toJson() => {
    'newClient': first.toJson(),
    'sameClient': second.toJson(),
  };
}

Uri validateProbeUrl(String value) {
  final uri = Uri.parse(value);
  if (uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw FormatException(
      'URL must be HTTPS without userinfo, query, or fragment',
    );
  }
  return uri;
}

Uri validateProxy(String value) {
  final uri = Uri.parse(value);
  final explicitPort = RegExp(r':([0-9]+)/?$').firstMatch(value);
  if (uri.scheme != 'http' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      explicitPort == null ||
      int.tryParse(explicitPort.group(1)!) != uri.port ||
      uri.port < 1 ||
      uri.port > 65535 ||
      !RegExp(r'^[A-Za-z0-9.\-:\[\]]+$').hasMatch(uri.authority) ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    throw FormatException('Proxy must be a credential-free HTTP authority');
  }
  return uri;
}

int median(List<int> values) {
  if (values.isEmpty) throw ArgumentError('median requires values');
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : ((sorted[middle - 1] + sorted[middle]) / 2).round();
}

class HttpsLatencyProbe {
  HttpsLatencyProbe({
    required this.timeout,
    this.maxBodyBytes = 65536,
    ProbeClientFactory? clientFactory,
  }) : clientFactory = clientFactory ?? HttpClient.new {
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 30)) {
      throw ArgumentError.value(timeout, 'timeout');
    }
    if (maxBodyBytes < 1 || maxBodyBytes > 1048576) {
      throw ArgumentError.value(maxBodyBytes, 'maxBodyBytes');
    }
  }
  final Duration timeout;
  final int maxBodyBytes;
  final ProbeClientFactory clientFactory;

  Future<ProbePair> measurePair(Uri uri) async {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(
        uri,
        'uri',
        'Must be HTTPS without userinfo, query, or fragment',
      );
    }
    final client = clientFactory();
    try {
      final first = await _request(client, uri);
      final second = first.outcome == 'success'
          ? await _request(client, uri, previous: first._connection)
          : ProbeSample(outcome: 'skipped');
      return ProbePair(first, second);
    } finally {
      client.close(force: true);
    }
  }

  Future<ProbeSample> _request(
    HttpClient client,
    Uri uri, {
    _Connection? previous,
  }) async {
    final watch = Stopwatch()..start();
    StreamSubscription<List<int>>? subscription;
    try {
      final result =
          await (() async {
            final request = await client.getUrl(uri);
            request.followRedirects = false;
            request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
            final response = await request.close();
            final headerMs = watch.elapsedMilliseconds;
            final connection = response.connectionInfo;
            final current = _Connection.from(connection);
            final reused =
                previous == null || !previous.isKnown || !current.isKnown
                ? null
                : current == previous;
            final length = response.contentLength;
            if (length > maxBodyBytes) {
              client.close(force: true);
              return _Result(
                ProbeSample(
                  outcome: 'body_too_large',
                  statusCode: response.statusCode,
                  headerMs: headerMs,
                  reused: reused,
                ),
                _Connection.from(connection),
              );
            }
            var bytes = 0;
            final completer = Completer<void>();
            subscription = response.listen(
              (chunk) {
                bytes += chunk.length;
                if (bytes > maxBodyBytes) {
                  client.close(force: true);
                  subscription?.cancel();
                  if (!completer.isCompleted) {
                    completer.completeError(const _TooLarge());
                  }
                }
              },
              onError: (Object _) {
                if (!completer.isCompleted) {
                  completer.completeError(const _Transport());
                }
              },
              onDone: () {
                if (!completer.isCompleted) completer.complete();
              },
            );
            await completer.future;
            final bodyMs = watch.elapsedMilliseconds;
            final status = response.statusCode;
            return _Result(
              ProbeSample(
                outcome: status >= 200 && status < 300
                    ? 'success'
                    : 'http_error',
                statusCode: status,
                bytes: bytes,
                headerMs: headerMs,
                bodyMs: bodyMs,
                reused: reused,
              ),
              _Connection.from(connection),
            );
          })().timeout(
            timeout,
            onTimeout: () {
              client.close(force: true);
              throw TimeoutException('probe timeout');
            },
          );
      return result.sample.._connection = result.connection;
    } on TimeoutException {
      return ProbeSample(
        outcome: 'timeout',
        reused: previous == null ? null : false,
      );
    } on _TooLarge {
      return ProbeSample(outcome: 'body_too_large');
    } on _Transport {
      return ProbeSample(outcome: 'transport_error');
    } on HandshakeException {
      return ProbeSample(outcome: 'tls_error');
    } on SocketException {
      return ProbeSample(outcome: 'transport_error');
    } on Object {
      return ProbeSample(outcome: 'transport_error');
    } finally {
      await subscription?.cancel();
    }
  }
}

class _Connection {
  const _Connection(this.localPort, this.remoteAddress, this.remotePort);
  final int? localPort;
  final String? remoteAddress;
  final int? remotePort;
  factory _Connection.from(HttpConnectionInfo? info) => _Connection(
    info?.localPort,
    info?.remoteAddress.address,
    info?.remotePort,
  );
  bool get isKnown =>
      localPort != null && remoteAddress != null && remotePort != null;

  @override
  bool operator ==(Object other) =>
      other is _Connection &&
      isKnown &&
      other.isKnown &&
      localPort == other.localPort &&
      remoteAddress == other.remoteAddress &&
      remotePort == other.remotePort;
  @override
  int get hashCode => Object.hash(localPort, remoteAddress, remotePort);
}

class _Result {
  _Result(this.sample, this.connection);
  final ProbeSample sample;
  final _Connection connection;
}

class _TooLarge implements Exception {
  const _TooLarge();
}

class _Transport implements Exception {
  const _Transport();
}
