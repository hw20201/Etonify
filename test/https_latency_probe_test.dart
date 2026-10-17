import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/core/network/https_latency_probe.dart';

void main() {
  late HttpServer server;
  late SecurityContext trust;
  late String base;
  var closes = false;
  var slowBody = false;
  var oversizedChunked = false;

  setUpAll(() async {
    final cert = File('test/fixtures/https_probe/localhost-cert.pem');
    final key = File('test/fixtures/https_probe/localhost-key.pem');
    trust = SecurityContext()..setTrustedCertificates(cert.path);
    server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      SecurityContext()
        ..useCertificateChain(cert.path)
        ..usePrivateKey(key.path),
    );
    base = 'https://localhost:${server.port}';
    server.listen((request) async {
      try {
        if (closes) {
          request.response.headers.set(HttpHeaders.connectionHeader, 'close');
        }
        if (oversizedChunked && request.uri.path != '/chunk') {
          request.response.headers.chunkedTransferEncoding = true;
        }
        if (request.uri.path == '/slow-headers') {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          request.response.add([1]);
        } else if (request.uri.path == '/declared') {
          request.response.contentLength = 100;
          request.response.add([1, 2, 3]);
        } else if (request.uri.path == '/redirect') {
          request.response.statusCode = 302;
          request.response.headers.set(HttpHeaders.locationHeader, '/ok');
        } else if (request.uri.path == '/slow') {
          request.response.headers.contentType = ContentType.text;
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          request.response.write('late');
        } else if (request.uri.path == '/chunk') {
          request.response.headers.chunkedTransferEncoding = true;
          request.response.add([1, 2, 3, 4, 5, 6]);
        } else {
          request.response.add([1, 2, 3]);
        }
        if (slowBody && request.uri.path != '/slow') {
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          request.response.add([4]);
        }
        if (oversizedChunked && request.uri.path != '/chunk') {
          request.response.add(List<int>.filled(8, 9));
        }
        await request.response.close();
      } on SocketException {
        // Expected when a probe closes early on timeout/body limits.
      } on HttpException {
        // Expected when a probe closes early on timeout/body limits.
      }
    });
  });

  tearDownAll(() async => server.close(force: true));

  HttpsLatencyProbe probe({
    Duration timeout = const Duration(seconds: 2),
    int max = 64,
    SecurityContext? context,
  }) => HttpsLatencyProbe(
    timeout: timeout,
    maxBodyBytes: max,
    clientFactory: () =>
        HttpClient(context: context ?? trust)..findProxy = (_) => 'DIRECT',
  );

  test('consumes complete body and verifies same socket reuse', () async {
    final pair = await probe().measurePair(Uri.parse('$base/ok'));
    expect(pair.first.outcome, 'success');
    expect(pair.first.statusCode, 200);
    expect(pair.first.bytes, 3);
    expect(pair.first.headerMs, isNotNull);
    expect(pair.first.bodyMs, greaterThanOrEqualTo(pair.first.headerMs!));
    expect(pair.second.outcome, 'success');
    expect(pair.second.bytes, 3);
    expect(pair.second.reused, isTrue);
    final serialized = pair.toJson().toString();
    expect(serialized, isNot(contains('127.0.0.1')));
    expect(serialized, isNot(contains('localPort')));
    expect(serialized, isNot(contains('remoteAddress')));
  });

  test('Connection close re-connect does not verify reuse', () async {
    closes = true;
    addTearDown(() => closes = false);
    final pair = await probe().measurePair(Uri.parse('$base/ok'));
    expect(pair.first.outcome, 'success');
    expect(pair.second.outcome, 'success');
    expect(pair.second.reused, isFalse);
  });

  test('untrusted TLS certificate is rejected', () async {
    final pair = await probe(
      context: SecurityContext(withTrustedRoots: false),
    ).measurePair(Uri.parse('$base/ok'));
    expect(pair.first.outcome, 'tls_error');
    expect(pair.second.outcome, 'skipped');
  });

  test('redirect is not followed', () async {
    final pair = await probe().measurePair(Uri.parse('$base/redirect'));
    expect(pair.first.outcome, 'http_error');
    expect(pair.first.statusCode, 302);
  });

  test('declared and streamed oversized bodies are rejected', () async {
    final declared = await probe(
      max: 4,
    ).measurePair(Uri.parse('$base/declared'));
    expect(declared.first.outcome, 'body_too_large');
    oversizedChunked = true;
    addTearDown(() => oversizedChunked = false);
    final streamed = await probe(max: 4).measurePair(Uri.parse('$base/chunk'));
    expect(streamed.first.outcome, 'body_too_large');
  });

  test('header and slow body are bounded by overall timeout', () async {
    final headerTimeout = await probe(
      timeout: const Duration(milliseconds: 80),
    ).measurePair(Uri.parse('$base/slow-headers'));
    expect(headerTimeout.first.outcome, 'timeout');
    slowBody = true;
    addTearDown(() => slowBody = false);
    final bodyTimeout = await probe(
      timeout: const Duration(milliseconds: 80),
    ).measurePair(Uri.parse('$base/ok'));
    expect(bodyTimeout.first.outcome, 'timeout');
  });

  test('validates url, proxy, medians and documented limits', () {
    expect(() => validateProbeUrl('http://localhost/'), throwsFormatException);
    expect(
      () => validateProbeUrl('https://u:p@localhost/'),
      throwsFormatException,
    );
    expect(
      () => validateProbeUrl('https://localhost/?x=1'),
      throwsFormatException,
    );
    expect(() => validateProxy('https://localhost:8'), throwsFormatException);
    expect(
      () => validateProxy('http://u:p@localhost:8'),
      throwsFormatException,
    );
    expect(
      () => validateProxy('http://host;DIRECT:8080'),
      throwsFormatException,
    );
    expect(() => validateProxy('http://host:0'), throwsFormatException);
    expect(() => validateProxy('http://host'), throwsFormatException);
    expect(validateProxy('http://host:80').port, 80);
    expect(validateProxy('http://[::1]:8080').authority, '[::1]:8080');
    expect(
      () => HttpsLatencyProbe(timeout: Duration.zero),
      throwsArgumentError,
    );
    expect(
      () => HttpsLatencyProbe(
        timeout: const Duration(seconds: 1),
        maxBodyBytes: 1048577,
      ),
      throwsArgumentError,
    );
    expect(
      () => probe().measurePair(Uri.parse('http://localhost/')),
      throwsArgumentError,
    );
    expect(median([1, 9, 4]), 4);
    expect(median([1, 9]), 5);
  });
}
