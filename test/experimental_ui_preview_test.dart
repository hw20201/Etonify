// Real Flutter widgets, synthetic subscription/IP data; not a device/VPN test.
// Optional screenshots:
// ETONIFY_PREVIEW_DIR=/absolute/output ETONIFY_PREVIEW_FONT=/path/font.ttf \
//   flutter test test/experimental_ui_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/experimental_home_shell.dart';
import 'package:meow_client/features/home/home_page.dart';
import 'package:meow_client/features/home/home_presentation.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';
import 'package:meow_client/features/proxies/proxies_page.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/models/app_view_models.dart';
import 'package:meow_client/models/home_navigation_mode.dart';
import 'package:meow_client/theme/app_theme.dart';

const _captureKey = ValueKey('preview-capture');

void main() {
  final output = Platform.environment['ETONIFY_PREVIEW_DIR'];
  final font = Platform.environment['ETONIFY_PREVIEW_FONT'];
  setUpAll(() async {
    if (font != null) {
      final data = ByteData.sublistView(await File(font).readAsBytes());
      for (final family in ['PreviewSans', 'Roboto', 'Ahem']) {
        await (FontLoader(family)..addFont(Future.value(data))).load();
      }
    }
    // Widget tests use Ahem by default; load the actual app icon assets.
    for (final entry in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/fluentui_system_icons/FluentSystemIcons-Regular':
          'packages/fluentui_system_icons/fonts/FluentSystemIcons-Regular.ttf',
      'packages/fluentui_system_icons/FluentSystemIcons-Filled':
          'packages/fluentui_system_icons/fonts/FluentSystemIcons-Filled.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  Future<void> capture(WidgetTester tester, String name) async {
    if (output == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final mode in [HomeNavigationMode.floating, HomeNavigationMode.docked]) {
    testWidgets('real widgets preview: ${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ip = PublicIpController(
        load: () async => const PublicIpInfo(
          ip: '203.0.113.24',
          countryCode: 'JP',
          country: '日本',
          city: '东京',
          organization: '示例网络（预览数据）',
          asn: 'AS64500',
          isp: '示例运营商',
        ),
      );
      final base = buildAppTheme(Brightness.dark);
      final theme = font == null
          ? base
          : base.copyWith(
              textTheme: base.textTheme.apply(fontFamily: 'PreviewSans'),
              primaryTextTheme: base.primaryTextTheme.apply(
                fontFamily: 'PreviewSans',
              ),
            );
      await tester.pumpWidget(
        RepaintBoundary(
          key: _captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ExperimentalHomeShell(
              mode: mode,
              homeBuilder: (_) => _home(ip),
              proxiesBuilder: (_) => ProxiesPage(
                profileId: 'preview',
                proxies: _proxies,
                selectedTag: 'tokyo',
                activeProxy: _proxies.first,
                connected: true,
                serverCount: _proxies.length,
                externalNavigationBar: true,
                progressiveBlurEnabled: false,
                hapticEnabled: false,
                onSelected: (_) {},
                onUrlTest: () async {},
                onProxyUrlTest: (_) async {},
              ),
              settingsBuilder: (_) =>
                  const Scaffold(body: Center(child: Text('设置'))),
              onProxiesRequested: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('outbound-ip-capsule')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, '${mode.name}-home');
      if (mode == HomeNavigationMode.floating) {
        await tester.tap(find.byKey(const ValueKey('outbound-ip-capsule')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('outbound-ip-details-card')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await capture(tester, 'floating-ip-overlay');
        await tester.tap(find.byKey(const ValueKey('outbound-ip-close')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('experimental-tab-proxies')));
      await tester.pumpAndSettle();
      expect(find.text('东京 · 01'), findsWidgets);
      expect(tester.takeException(), isNull);
      await capture(tester, '${mode.name}-servers');
      if (mode == HomeNavigationMode.floating) {
        await tester.tap(find.byKey(const ValueKey('proxy-search-open')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('proxy-search-field')),
          '香港',
        );
        await tester.pumpAndSettle();
        await capture(tester, 'floating-search-dialog');
        await tester.tap(find.byKey(const ValueKey('proxy-search-apply')));
        await tester.pumpAndSettle();
        expect(find.text('香港 · 01'), findsOneWidget);
        expect(find.text('东京 · 01'), findsNothing);
        expect(tester.takeException(), isNull);
        await capture(tester, 'floating-search-results');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      ip.dispose();
    });
  }
}

Widget _home(PublicIpController ip) => HomePage(
  bottomInset: 0,
  state: HomeViewState(
    connected: true,
    connecting: false,
    resolvingProxy: false,
    connectionStatusLabel: '已连接',
    activeProfile: const AppProfileSummary(
      id: 'preview',
      name: '试验预览 · 示例订阅',
      consumed: 18.0 * 1024 * 1024 * 1024,
      total: 100.0 * 1024 * 1024 * 1024,
      remainingDays: 28,
      outboundsCount: 6,
      sourceLabel: 'example.invalid',
    ),
    activeProxy: _proxies.first,
    publicIpController: ip,
    hideServerIp: false,
    hapticEnabled: false,
    speedBytesPerSecond: 1280000,
    trafficBytes: 1800000000,
    brandName: 'Etonify',
    versionLabel: '0.3.106',
  ),
  actions: HomeViewActions(
    toggleConnection: () {},
    refreshLatency: () {},
    openSubscriptions: () {},
    addSubscription: () {},
    openSettings: () {},
    openChangelog: () {},
  ),
);

final _proxies = [
  _proxy('tokyo', '东京 · 01', 'JP', 48),
  _proxy('hk1', '香港 · 01', 'HK', 32),
  _proxy('hk2', '香港 · 02', 'HK', 39),
  _proxy('sg', '新加坡 · 01', 'SG', 76),
  _proxy('us', '洛杉矶 · 01', 'US', 148),
  _proxy('de', '法兰克福 · 01', 'DE', 181),
];

AppProxySummary _proxy(String tag, String name, String country, int latency) =>
    AppProxySummary(
      tag: tag,
      displayName: name,
      countryCode: country,
      type: 'vless',
      server: '$tag.example.invalid',
      port: 443,
      detailText: 'VLESS · TLS',
      ip: '203.0.113.24',
      latency: latency,
      latencyFresh: true,
      latencyChecking: false,
      latencyUnavailable: false,
      latencyError: null,
      protocolLabel: 'VLESS',
      endpointLabel: '$tag.example.invalid:443',
    );
