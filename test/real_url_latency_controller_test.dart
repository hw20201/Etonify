import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/app/real_url_latency_controller.dart';

void main() {
  const url = 'https://example.test/latency';
  Map<String, dynamic> response(int status, [String finalUrl = url]) => {
    'statusCode': status,
    'finalUrl': finalUrl,
  };

  test('success, HTTP failure and concurrent workers', () async {
    var active = 0;
    var peak = 0;
    final controller = RealUrlLatencyController(
      fetch:
          ({
            required outboundTag,
            required uri,
            required headers,
            required maxBytes,
            required timeout,
          }) async {
            active++;
            if (active > peak) peak = active;
            await Future<void>.delayed(const Duration(milliseconds: 15));
            active--;
            return response(outboundTag == 'bad' ? 503 : 200);
          },
    );
    await controller.run(
      ['a', 'bad', 'c'],
      url,
      const Duration(seconds: 2),
      2,
      () {},
    );
    expect(peak, 2);
    expect(controller.results['a']!.delayMs, greaterThanOrEqualTo(1));
    expect(controller.results['bad']!.error, 'http_error');
    expect(controller.completed, 3);
    expect(controller.total, 3);
    expect(controller.isRunning, isFalse);
  });

  test(
    'single-node retest preserves other real URL results and request bounds',
    () async {
      final controller = RealUrlLatencyController(
        fetch:
            ({
              required outboundTag,
              required uri,
              required headers,
              required maxBytes,
              required timeout,
            }) async {
              expect(headers, {
                'Accept-Encoding': 'identity',
                'Cache-Control': 'no-cache',
              });
              expect(maxBytes, 65536);
              expect(timeout, const Duration(seconds: 30));
              return response(204);
            },
      );
      await controller.run(['a'], url, const Duration(seconds: 90), 100, () {});
      await controller.run(['b'], url, const Duration(seconds: 90), 100, () {});
      expect(controller.results.keys, containsAll(['a', 'b']));
      expect(controller.completed, 1);
      expect(controller.total, 1);
      controller.clear();
      expect(controller.results, isEmpty);
    },
  );
  test('invalid URL is rejected before fetch', () async {
    var calls = 0;
    final controller = RealUrlLatencyController(
      fetch:
          ({
            required outboundTag,
            required uri,
            required headers,
            required maxBytes,
            required timeout,
          }) async {
            calls++;
            return response(200);
          },
    );
    await controller.run(
      ['a'],
      'http://example.test',
      const Duration(seconds: 2),
      1,
      () {},
    );
    expect(calls, 0);
    expect(controller.results['a']!.error, 'invalid_url');
  });

  test(
    'late callbacks after cancel are discarded; clear resets session',
    () async {
      final completer = Completer<Map<String, dynamic>>();
      final controller = RealUrlLatencyController(
        fetch:
            ({
              required outboundTag,
              required uri,
              required headers,
              required maxBytes,
              required timeout,
            }) => completer.future,
      );
      final running = controller.run(
        ['a'],
        url,
        const Duration(seconds: 2),
        1,
        () {},
      );
      await Future<void>.delayed(Duration.zero);
      controller.cancel();
      completer.complete(response(200));
      await running;
      expect(controller.results, isEmpty);
      await controller.run(['b'], url, const Duration(seconds: 2), 1, () {});
      expect(controller.results.keys, ['b']);
      controller.clear();
      expect(controller.results, isEmpty);
      expect(controller.total, 0);
    },
  );

  test('timeout, empty and duplicate tags', () async {
    var calls = 0;
    final controller = RealUrlLatencyController(
      fetch:
          ({
            required outboundTag,
            required uri,
            required headers,
            required maxBytes,
            required timeout,
          }) {
            calls++;
            return Completer<Map<String, dynamic>>().future;
          },
    );
    await controller.run(
      ['', '  ', 'x', 'x', ' y '],
      url,
      const Duration(milliseconds: 10),
      99,
      () {},
    );
    expect(calls, 2);
    expect(controller.total, 2);
    expect(controller.results['x']!.error, 'timeout');
    expect(controller.results['y']!.error, 'timeout');
  });

  test('requires HTTPS final URL even on 2xx', () async {
    final controller = RealUrlLatencyController(
      fetch:
          ({
            required outboundTag,
            required uri,
            required headers,
            required maxBytes,
            required timeout,
          }) async => response(204, 'http://example.test/'),
    );
    await controller.run(['x'], url, const Duration(seconds: 1), 1, () {});
    expect(controller.results['x']!.error, 'http_error');
  });
}
