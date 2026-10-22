import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';

const sample = PublicIpInfo(ip: '203.0.113.9');

void main() {
  for (final dimension in [
    'provider',
    'outbound',
    'config',
    'core',
    'network',
  ]) {
    testWidgets('$dimension change clears cache and prevents stale backfill', (
      tester,
    ) async {
      var source = PublicIpSource.ipQuery;
      var outbound = 'proxy-a';
      var config = 'config-a';
      var core = 'core-a';
      var network = 7;
      var cancels = 0;
      final pending = Completer<PublicIpInfo>();
      final controller = PublicIpController(
        load: () => pending.future,
        cancel: () => cancels++,
        sourceProvider: () => source,
        outboundProvider: () => outbound,
        networkGenerationProvider: () => network,
        scopeProvider: () => (config, core),
      );
      final operation = controller.refresh();
      switch (dimension) {
        case 'provider':
          source = PublicIpSource.ipWho;
        case 'outbound':
          outbound = 'proxy-b';
        case 'config':
          config = 'config-b';
        case 'core':
          core = 'core-b';
        case 'network':
          network++;
      }
      controller.synchronizeScope();
      expect(cancels, 1);
      expect(controller.loading, isFalse);
      pending.complete(sample);
      await operation;
      expect(controller.info, isNull);
      expect(controller.failed, isFalse);
      expect(controller.canRefresh, isTrue);
      controller.dispose();
    });
  }

  testWidgets('unchanged group snapshots do not cancel active query', (
    tester,
  ) async {
    var cancels = 0;
    final pending = Completer<PublicIpInfo>();
    final controller = PublicIpController(
      load: () => pending.future,
      cancel: () => cancels++,
      scopeProvider: () => ('same-config', 7),
    );
    final operation = controller.refresh();
    for (var i = 0; i < 10; i++) {
      controller.synchronizeScope();
    }
    expect(cancels, 0);
    pending.complete(sample);
    await operation;
    expect(controller.info, same(sample));
    controller.dispose();
  });

  testWidgets(
    'scope mismatch without an event still hides cache and rejects completion',
    (tester) async {
      var scope = 'before';
      var calls = 0;
      final second = Completer<PublicIpInfo>();
      final controller = PublicIpController(
        load: () async {
          calls++;
          return calls == 1 ? sample : second.future;
        },
        scopeProvider: () => scope,
      );
      await controller.refresh();
      expect(controller.info, same(sample));
      scope = 'after';
      expect(controller.info, isNull);
      final operation = controller.refresh();
      scope = 'newer';
      second.complete(sample);
      await operation;
      expect(controller.info, isNull);
      controller.dispose();
    },
  );
}
