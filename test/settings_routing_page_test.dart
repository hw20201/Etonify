import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/app/app_settings_controller.dart';
import 'package:meow_client/app/providers/app_dependency_providers.dart';
import 'package:meow_client/app/providers/app_settings_commands_provider.dart';
import 'package:meow_client/app/providers/app_settings_provider.dart';
import 'package:meow_client/data/adblock/ad_block_rule_set_service.dart';
import 'package:meow_client/data/local/app_settings_store.dart';
import 'package:meow_client/data/routing/custom_routing_rule.dart';
import 'package:meow_client/data/routing/china_route_data_service.dart';
import 'package:meow_client/data/routing/traffic_routing_mode.dart';
import 'package:meow_client/features/settings/custom_routing_rules_page.dart';
import 'package:meow_client/features/settings/settings_routing_page.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/theme/app_theme.dart';

void main() {
  testWidgets('custom rules editor adds and routes a domain directly', (
    tester,
  ) async {
    List<CustomRoutingRule> saved = const [];
    await tester.binding.setSurfaceSize(const Size(420, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        theme: buildAppTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CustomRoutingRulesPage(
          currentRules: const [],
          onChanged: (value) => saved = value,
        ),
      ),
    );

    await tester.tap(find.text('添加规则'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'example.com');
    // The selectors expand inline instead of opening a popup menu.
    await tester.tap(find.text('走代理'));
    await tester.pumpAndSettle();
    expect(find.text('直连'), findsOneWidget);
    await tester.tap(find.text('直连'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(saved.single.type, CustomRouteRuleType.domain);
    expect(saved.single.value, 'example.com');
    expect(saved.single.action, CustomRouteAction.direct);
    expect(find.text('域名 · 直连'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  const readyFilter = AdBlockRuleSetStatus(
    available: true,
    providerName: 'AdGuard DNS Filter',
    sourceUrl: AdBlockRuleSetService.sourceUrl,
    blockRuleSetPath: '/filter.srs',
    blockedDomainCount: 120,
  );

  testWidgets('first filter action prepares before enabling blocking', (
    tester,
  ) async {
    final download = Completer<AdBlockRuleSetStatus>();
    final enabledValues = <bool>[];
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Фильтр ещё не скачан',
      downloadAdBlock: () => download.future,
      onAdBlockEnabled: enabledValues.add,
    );
    expect(find.text('Включить локальную блокировку'), findsNothing);
    expect(
      find.text(
        'Скачиваем список с AdGuard и сохраняем его локально для sing-box.',
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(find.text('Скачать и включить'), 150);
    await tester.tap(find.text('Скачать и включить'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(enabledValues, isEmpty);
    download.complete(readyFilter);
    await tester.pumpAndSettle();
    expect(enabledValues, [true]);
    expect(find.text('Включить локальную блокировку'), findsOneWidget);
    expect(find.text('Обновить'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
  });

  testWidgets('failed first filter download stays off and can retry', (
    tester,
  ) async {
    final enabledValues = <bool>[];
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Фильтр ещё не скачан',
      downloadAdBlock: () async => throw StateError('offline'),
      onAdBlockEnabled: enabledValues.add,
    );
    await tester.scrollUntilVisible(find.text('Скачать и включить'), 150);
    await tester.tap(find.text('Скачать и включить'));
    await tester.pumpAndSettle();
    expect(enabledValues, isEmpty);
    expect(find.text('Фильтр ещё не скачан'), findsOneWidget);
    expect(find.text('Скачать и включить'), findsOneWidget);
    expect(find.text('Включить локальную блокировку'), findsNothing);
  });

  testWidgets('deleting a prepared filter does not report a download', (
    tester,
  ) async {
    final deletion = Completer<AdBlockRuleSetStatus>();
    final enabledValues = <bool>[];
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Удалить',
      adBlockStatus: readyFilter,
      adBlockEnabled: true,
      deleteAdBlock: () => deletion.future,
      onAdBlockEnabled: enabledValues.add,
    );
    await tester.tap(find.text('Удалить'));
    await tester.pump();
    expect(find.text('Скачиваем и собираем локальный фильтр...'), findsNothing);
    expect(find.text('Удаляем фильтр…'), findsOneWidget);
    expect(enabledValues, isEmpty);
    deletion.complete(const AdBlockRuleSetStatus.unavailable());
    await tester.pumpAndSettle();
    expect(enabledValues, [false]);
    expect(find.text('Скачать и включить'), findsOneWidget);
    expect(find.text('Включить локальную блокировку'), findsNothing);
  });

  testWidgets('failed filter update retains ready filter and enabled state', (
    tester,
  ) async {
    final enabledValues = <bool>[];
    final controller = await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Обновить',
      adBlockStatus: readyFilter,
      adBlockEnabled: true,
      downloadAdBlock: () async => throw StateError('offline'),
      onAdBlockEnabled: enabledValues.add,
    );
    await tester.tap(find.text('Обновить'));
    await tester.pumpAndSettle();
    expect(controller.adBlockEnabled, isTrue);
    expect(enabledValues, isEmpty);
    expect(find.text('Фильтр готов, доменов: 120'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
  });

  testWidgets('routing mode switches between rules and global', (tester) async {
    final controller = await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Глобальный',
    );
    expect(find.byType(SegmentedButton<TrafficRoutingMode>), findsOneWidget);
    expect(find.text('По правилам'), findsOneWidget);
    expect(find.text('Глобальный'), findsOneWidget);
    await tester.tap(find.text('Глобальный'));
    await tester.pumpAndSettle();
    expect(controller.routingMode, TrafficRoutingMode.global);
    expect(find.text('Нейросети через VPN'), findsNothing);
    expect(find.text('Социальные сети через VPN'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('large text keeps the mode selector and rule entry reachable', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      textScale: 1.6,
      scrollTo: 'Глобальный',
    );
    expect(find.byType(SegmentedButton<TrafficRoutingMode>), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Свои правила доменов и IP'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Свои правила доменов и IP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'large text and keyboard keep controls reachable without overflow',
    (tester) async {
      await _pumpPage(
        tester,
        const ChinaRouteDataStatus.unavailable(),
        textScale: 1.6,
        keyboardInset: 300,
        installedApps: [
          {'packageName': 'com.example.app', 'label': 'Example'},
        ],
        scrollTo: 'Раздельная маршрутизация',
      );
      await tester.tap(find.text('Раздельная маршрутизация'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Example'),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('split-routing-app-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Example'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('split-routing-apply')), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets('app lists remain independent drafts until Apply', (
    tester,
  ) async {
    var applies = 0;
    final controller = await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      installedApps: [
        {'packageName': 'org.telegram.messenger', 'label': 'Telegram'},
        {'packageName': 'com.example.mail', 'label': 'Mail'},
      ],
      scrollTo: 'Раздельная маршрутизация',
      onSplitRoutingPackagesChanged: (_) => applies++,
    );
    await tester.tap(find.text('Раздельная маршрутизация'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.tap(
      find.byKey(const ValueKey('split-app-org.telegram.messenger')),
    );
    await tester.tap(find.text('Вне VPN'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('split-app-com.example.mail')));
    await tester.tap(find.text('Через VPN'));
    await tester.pumpAndSettle();
    expect(applies, 0);
    expect(controller.splitRoutingMode, SplitRoutingMode.disabled);
    final telegram = find.descendant(
      of: find.byKey(const ValueKey('split-app-org.telegram.messenger')),
      matching: find.byType(Checkbox),
    );
    expect(tester.widget<Checkbox>(telegram).value, isTrue);
    await tester.tap(find.byKey(const ValueKey('split-routing-apply')));
    await tester.pumpAndSettle();
    expect(applies, 1);
    expect(controller.splitRoutingIncludedPackages, ['org.telegram.messenger']);
    expect(controller.splitRoutingExcludedPackages, ['com.example.mail']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'empty cache still loads apps when old selected package is missing',
    (tester) async {
      await _pumpPage(
        tester,
        const ChinaRouteDataStatus.unavailable(),
        splitRoutingMode: SplitRoutingMode.proxySelected,
        splitRoutingPackages: ['com.old.removed'],
        preloadApps: [
          {'packageName': 'com.google.android.youtube', 'label': 'YouTube'},
        ],
        scrollTo: 'Раздельная маршрутизация',
      );
      await tester.tap(find.text('Раздельная маршрутизация'));
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('com.old.removed'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('large app catalog builds only viewport and searches packages', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      installedApps: List.generate(
        1000,
        (i) => {'packageName': 'com.example.app$i', 'label': 'App $i'},
      ),
      scrollTo: 'Раздельная маршрутизация',
    );
    await tester.tap(find.text('Раздельная маршрутизация'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox).evaluate().length, lessThan(25));
    await tester.enterText(find.byType(TextField), 'com.example.app999');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpAndSettle();
    expect(find.text('App 999'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('enabled empty app list is never applied as unrestricted VPN', (
    tester,
  ) async {
    List<String>? applied;
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Раздельная маршрутизация',
      onSplitRoutingPackagesChanged: (v) => applied = v,
    );
    await tester.tap(find.text('Раздельная маршрутизация'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.tap(find.byKey(const ValueKey('split-routing-apply')));
    await tester.pumpAndSettle();
    expect(applied, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  testWidgets('split routing opens a dedicated page with independent modes', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Раздельная маршрутизация',
    );
    await tester.tap(find.text('Раздельная маршрутизация'));
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<SplitRoutingMode>), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const ValueKey('split-routing-apply')), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  testWidgets('custom routing rules open from the routing settings page', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      scrollTo: 'Свои правила доменов и IP',
    );

    expect(find.text('Свои правила доменов и IP'), findsOneWidget);
    await tester.tap(find.text('Свои правила доменов и IP'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomRoutingRulesPage), findsOneWidget);
    expect(find.text('Добавить правило'), findsOneWidget);
    expect(find.text('Нейросети через VPN'), findsNothing);
    expect(find.text('Социальные сети через VPN'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('selected split app keeps name and package on separate rows', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      splitRoutingMode: SplitRoutingMode.bypassSelected,
      splitRoutingPackages: const ['org.telegram.messenger'],
      installedApps: const [
        {
          'packageName': 'org.telegram.messenger',
          'label': 'Telegram',
          'system': false,
          'launchable': true,
        },
      ],
      scrollTo: 'Telegram',
    );

    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('org.telegram.messenger'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('missing selected app does not repeat package as its name', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      splitRoutingMode: SplitRoutingMode.bypassSelected,
      splitRoutingPackages: const ['com.example.removed'],
      scrollTo: 'Приложение не найдено',
    );

    expect(find.text('Приложение не найдено'), findsOneWidget);
    expect(find.text('com.example.removed'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('selected split app can be removed without reopening picker', (
    tester,
  ) async {
    List<String>? changedPackages;
    await _pumpPage(
      tester,
      const ChinaRouteDataStatus.unavailable(),
      splitRoutingMode: SplitRoutingMode.bypassSelected,
      splitRoutingPackages: const ['org.telegram.messenger'],
      installedApps: const [
        {
          'packageName': 'org.telegram.messenger',
          'label': 'Telegram',
          'system': false,
          'launchable': true,
        },
      ],
      scrollTo: 'Telegram',
      onSplitRoutingPackagesChanged: (value) => changedPackages = value,
    );

    await tester.tap(
      find.byKey(const ValueKey('split-app-org.telegram.messenger')),
    );
    await tester.pumpAndSettle();
    // Selecting a row is a draft; disable the now-empty mode before applying.
    expect(changedPackages, isNull);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('split-routing-apply')));
    await tester.pumpAndSettle();
    expect(changedPackages, isEmpty);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}

Future<AppSettingsController> _pumpPage(
  WidgetTester tester,
  ChinaRouteDataStatus routeStatus, {
  SplitRoutingMode splitRoutingMode = SplitRoutingMode.disabled,
  List<String> splitRoutingPackages = const [],
  List<Map<String, dynamic>> installedApps = const [],
  List<Map<String, dynamic>>? preloadApps,
  double textScale = 1,
  double keyboardInset = 0,
  String scrollTo = 'Свои правила доменов и IP',
  ValueChanged<List<String>>? onSplitRoutingPackagesChanged,
  AdBlockRuleSetStatus adBlockStatus = const AdBlockRuleSetStatus.unavailable(),
  bool adBlockEnabled = false,
  Future<AdBlockRuleSetStatus> Function()? downloadAdBlock,
  Future<AdBlockRuleSetStatus> Function()? deleteAdBlock,
  ValueChanged<bool>? onAdBlockEnabled,
  TrafficRoutingMode routingMode = TrafficRoutingMode.rules,
  List<CustomRoutingRule> customRoutingRules = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 860));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final controller = AppSettingsController()
    ..blockLeaks = true
    ..adBlockEnabled = adBlockEnabled
    ..routingMode = routingMode
    ..customRoutingRules = customRoutingRules
    ..russiaDnsDirectResolver = 'udp://77.88.8.8'
    ..bypassLocalNetwork = true
    ..vpnInboundEnabled = true
    ..splitRoutingMode = splitRoutingMode
    ..splitRoutingPackages = splitRoutingPackages;

  final commands = AppSettingsCommands();
  commands.bindRoutingHandlers(
    setBlockLeaks: (_) {},
    setAdBlockEnabled: onAdBlockEnabled ?? (_) {},
    downloadAdBlockRuleSet:
        downloadAdBlock ?? () async => const AdBlockRuleSetStatus.unavailable(),
    deleteAdBlockRuleSet:
        deleteAdBlock ?? () async => const AdBlockRuleSetStatus.unavailable(),
    refreshRoutingRuleData: () async => routeStatus,
    setTrafficRoutingMode: controller.setRoutingMode,
    setCustomRoutingRules: controller.setCustomRoutingRules,
    prepareChinaRouteData: () async => routeStatus,
    setRussiaDnsDirectResolver: (_) {},
    setBypassLocalNetwork: (_) {},
    setSplitRoutingMode: (_) {},
    setSplitRoutingPackages: onSplitRoutingPackagesChanged ?? (_) {},
    preloadInstalledApps: () async => preloadApps ?? installedApps,
    applySplitRoutingSettings: (mode, included, excluded) async {
      controller.setSplitRoutingSettings(
        mode: mode,
        included: included,
        excluded: excluded,
      );
      onSplitRoutingPackagesChanged?.call(controller.splitRoutingPackages);
      return true;
    },
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsControllerProvider.overrideWithValue(controller),
        appSettingsCommandsProvider.overrideWithValue(commands),
        adBlockStatusProvider.overrideWith(
          () => AdBlockStatusNotifier(adBlockStatus),
        ),
        chinaRouteDataStatusProvider.overrideWith(
          () => ChinaRouteDataStatusNotifier(routeStatus),
        ),
        installedAppsCacheProvider.overrideWith(
          () => InstalledAppsCacheNotifier(installedApps),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: child!,
        ),
        locale: Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsRoutingPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final inSplitPage =
      scrollTo == 'Telegram' || scrollTo == 'Приложение не найдено';
  await tester.scrollUntilVisible(
    find.text(inSplitPage ? 'Раздельная маршрутизация' : scrollTo),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  if (inSplitPage) {
    await tester.tap(find.text('Раздельная маршрутизация'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(scrollTo),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  return controller;
}
