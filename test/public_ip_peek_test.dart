import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';
import 'package:meow_client/features/home/public_ip_peek.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('backdrop covers the root overlay outside a nested navigator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PublicIpController(
      load: () async => const PublicIpInfo(ip: '203.0.113.1'),
    );
    var backgroundTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 600,
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
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
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('outside-nested-overlay'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => backgroundTaps++,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final capsule = find.byKey(const ValueKey('outbound-ip-capsule'));
    final card = find.byKey(const ValueKey('outbound-ip-details-card'));
    final backdrop = find.byKey(const ValueKey('outbound-ip-overlay-backdrop'));
    final outside = find.byKey(const ValueKey('outside-nested-overlay'));

    await tester.tap(capsule);
    await tester.pumpAndSettle();
    expect(tester.getRect(backdrop), const Rect.fromLTWH(0, 0, 412, 915));
    expect(tester.getRect(card).bottom, lessThan(tester.getRect(capsule).top));
    expect(tester.widget<ColoredBox>(backdrop).color.a, closeTo(.12, .005));

    // A tap below the nested navigator must dismiss the card, not reach home.
    await tester.tapAt(tester.getCenter(outside));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    expect(backdrop, findsNothing);
    expect(backgroundTaps, 0);

    // Closing and reopening must keep the controller and anchor functional.
    await tester.tap(capsule);
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('outbound-ip-close')));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    await tester.tapAt(tester.getCenter(outside));
    expect(backgroundTaps, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    controller.dispose();
  });

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
        country: 'Japan',
        city: 'Tokyo',
        organization: 'Amazon Data Services LLC - Global Infrastructure',
        asn: 'AS16509',
        isp: 'Amazon ISP',
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
    expect(
      tester
          .widget<AnimatedRotation>(
            find.byKey(const ValueKey('outbound-ip-capsule-chevron')),
          )
          .turns,
      0,
    );
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
    expect(
      find.byKey(const ValueKey('outbound-ip-overlay-backdrop')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('outbound-ip-capsule-visibility')),
          )
          .opacity,
      0,
    );
    expect(
      tester
          .widget<AnimatedRotation>(
            find.byKey(const ValueKey('outbound-ip-capsule-chevron')),
          )
          .turns,
      .5,
    );
    expect(find.text('出站 IP'), findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.text('Amazon Data Services LLC - Global Infrastructure'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: card,
              matching: find.text(
                'Amazon Data Services LLC - Global Infrastructure',
              ),
            ),
          )
          .maxLines,
      isNull,
    );
    expect(find.text('国家 / 地区'), findsOneWidget);
    expect(find.textContaining('Japan'), findsOneWidget);
    expect(find.text('AS16509'), findsOneWidget);
    expect(find.text('ipquery.io'), findsOneWidget);
    expect(find.textContaining('纯净'), findsNothing);
    expect(find.textContaining('VPN'), findsNothing);
    expect(tester.getRect(card).bottom, lessThan(tester.getRect(capsule).top));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('outbound-ip-close')));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets(
    'respects the hide-IP preference and identifies the selected source',
    (tester) async {
      final controller = PublicIpController(
        load: () async => const PublicIpInfo(
          ip: '2001:db8:abcd:1234::1',
          source: PublicIpSource.ipApi,
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

  testWidgets('wraps long country and provider values on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const location = 'Singapore · Singapore - North East Region';
    const provider = 'Amazon Technologies Inc. Asia Pacific';
    final controller = PublicIpController(
      load: () async => const PublicIpInfo(
        ip: '13.214.126.247',
        countryCode: 'SG',
        country: 'Singapore',
        region: 'Singapore - North East Region',
        city: 'Singapore - North East Region',
        organization: 'Amazon.com, Inc.',
        asn: 'AS16509',
        isp: provider,
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
    await tester.tap(find.byKey(const ValueKey('outbound-ip-capsule')));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('outbound-ip-details-card'));
    final countryText = find.descendant(
      of: card,
      matching: find.text(location),
    );
    final providerText = find.descendant(
      of: card,
      matching: find.text(provider),
    );
    expect(countryText, findsOneWidget);
    expect(providerText, findsOneWidget);
    for (final finder in <Finder>[countryText, providerText]) {
      final text = tester.widget<Text>(finder);
      expect(text.maxLines, isNull);
      expect(text.overflow, TextOverflow.visible);
    }
    final layoutException = tester.takeException();
    expect(layoutException, isNull, reason: '$layoutException');
    controller.dispose();
  });
}
