import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';
import 'package:meow_client/features/home/public_ip_peek.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

void main() {
  test('every reviewed code is safe and unknown values are not rendered', () {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    for (final reason in PublicIpUnsupportedReason.values) {
      expect(PublicIpUnsupportedReason.parse(reason.diagnosticCode), reason);
      expect(
        publicIpUnsupportedMessage(l10n, reason, reason.diagnosticCode),
        contains(reason.diagnosticCode),
      );
    }
    expect(
      PublicIpUnsupportedReason.parse('outbound.protocol.direct'),
      PublicIpUnsupportedReason.outboundProtocolOther,
    );
    for (final code in [
      'outbound.option.inet4_bind_address',
      'outbound.option.inet6_bind_address',
      'dns.option.domain_resolver',
      'dns.option.tcp_multi_path',
    ]) {
      expect(PublicIpUnsupportedReason.parse(code), isNotNull);
    }
    for (final code in [
      'outbound.option.secret_address',
      'outbound.protocol.private-host.example',
      'dns.bootstrap] private-password',
    ]) {
      expect(PublicIpUnsupportedReason.parse(code), isNull);
      expect(
        publicIpUnsupportedMessage(
          l10n,
          PublicIpUnsupportedReason.outboundOption,
          code,
        ),
        l10n.trafficDashboardPublicIpUnsupported,
      );
    }
  });

  for (final cached in [false, true]) {
    for (final code in [
      'outbound.protocol.vless',
      'outbound.bootstrap.pin_required',
      'outbound.option.inet4_bind_address',
    ]) {
      testWidgets('safe diagnostic on narrow panel: $code cached=$cached', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var calls = 0;
        final controller = PublicIpController(
          load: () async {
            if (cached && calls++ == 0) {
              return const PublicIpInfo(ip: '203.0.113.1');
            }
            throw StateError(
              'rpc error: code = FailedPrecondition desc = unsupported scoped query configuration: [PIP_CFG:$code] private-password private-host.example',
            );
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: PublicIpPeek(
                  controller: controller,
                  connected: true,
                  hideIp: false,
                  hapticEnabled: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (cached) {
          await tester.pump(const Duration(seconds: 4));
          await controller.refresh();
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('outbound-ip-capsule')));
        await tester.pumpAndSettle();
        expect(controller.unsupportedDiagnosticCode, code);
        expect(find.textContaining(code), findsOneWidget);
        expect(find.textContaining('private-password'), findsNothing);
        expect(find.textContaining('private-host.example'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        controller.dispose();
      });
    }
  }
}
