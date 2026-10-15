import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';
import 'package:meow_client/features/home/public_ip_peek.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('capsule expands its themed detail card above the anchor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PublicIpController(
      load: () async => const PublicIpInfo(
        ip: '57.181.118.111',
        countryCode: 'JP',
        organization: 'Amazon.com, Inc.',
        asn: 'AS16509',
        isp: 'Amazon ISP',
        riskScore: 3,
        isDatacenter: true,
      ),
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
    await tester.pump();
    await tester.pumpAndSettle();

    final capsule = find.byKey(const ValueKey('outbound-ip-capsule'));
    expect(capsule, findsOneWidget);
    expect(find.text('57.181.118.111'), findsOneWidget);
    expect(find.text('IP 检测'), findsNothing);
    expect(
      find.byKey(const ValueKey('outbound-ip-details-card')),
      findsNothing,
    );

    await tester.tap(capsule);
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('outbound-ip-details-card'));
    expect(card, findsOneWidget);
    expect(find.text('出站 IP'), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Amazon.com, Inc.')),
      findsOneWidget,
    );
    expect(find.text('AS16509'), findsOneWidget);
    expect(find.text('ipquery.io'), findsOneWidget);
    expect(find.text('机房'), findsNWidgets(2));
    expect(tester.getRect(card).bottom, lessThan(tester.getRect(capsule).top));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('outbound-ip-close')));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets(
    'respects the hide-IP preference and identifies the backup source',
    (tester) async {
      final controller = PublicIpController(
        load: () async => const PublicIpInfo(
          ip: '2001:db8:abcd:1234::1',
          source: PublicIpSource.ipApi,
          isProxy: true,
        ),
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
                hideIp: true,
                hapticEnabled: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.textContaining('****'), findsOneWidget);
      expect(find.text('2001:db8:abcd:1234::1'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('outbound-ip-capsule')));
      await tester.pumpAndSettle();
      expect(find.text('ip-api.com'), findsOneWidget);
      expect(find.text('2001:db8:abcd:1234::1'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('outbound-ip-details-card')),
          matching: find.textContaining('****'),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 4));
      controller.dispose();
    },
  );
}
