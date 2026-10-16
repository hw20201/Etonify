import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/data/routing/china_route_data_service.dart';
import 'package:meow_client/features/settings/routing_rule_files_page.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('route page unlocks after an update started on another page', (
    tester,
  ) async {
    final activity = _FakeRouteActivity();
    addTearDown(activity.progress.dispose);
    const status = ChinaRouteDataStatus(
      available: true,
      sourceName: ChinaRouteDataService.chinaRouteDataSourceName,
      versionTag: '202609280600',
    );
    Widget build(ChinaRouteDataStatus currentStatus) => MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RoutingRuleFilesPage(
        currentStatus: currentStatus,
        onRefresh: () async => status,
        activity: activity,
      ),
    );
    await tester.pumpWidget(build(status));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      build(
        const ChinaRouteDataStatus(
          available: true,
          sourceName: ChinaRouteDataService.chinaRouteDataSourceName,
          versionTag: '202609290600',
        ),
      ),
    );

    activity.isUpdating = false;
    activity.progress.value = null;
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('29.09.2026 06:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('China route files use compact metadata and readable version', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const status = ChinaRouteDataStatus(
      available: true,
      sourceName: ChinaRouteDataService.chinaRouteDataSourceName,
      sourceKind: ChinaRouteDataService.sourceKindLive,
      versionTag: '202608261635',
      releaseTag: '202608261635',
      chinaGeositePath: '/test/geosite-cn.srs',
      chinaGeoipPath: '/test/geoip-cn.srs',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RoutingRuleFilesPage(
          currentStatus: status,
          onRefresh: () async => status,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Источник'), findsOneWidget);
    expect(find.text('SagerNet/sing-geosite + sing-geoip'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    expect(find.text('Версия'), findsOneWidget);
    expect(find.text('26.08.2026 16:35'), findsOneWidget);
    expect(find.text('Общий размер'), findsOneWidget);
    expect(find.text('0 B'), findsOneWidget);
    expect(find.text('Домены и IP-диапазоны Китая'), findsOneWidget);
    expect(
      find.text(
        'В режиме правил домены и IP Китая идут напрямую; остальной трафик '
        'идет через выбранный прокси.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.verified_rounded), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _FakeRouteActivity implements ChinaRouteUpdateActivity {
  @override
  bool isUpdating = true;
  @override
  final ValueNotifier<ChinaRouteUpdateProgress?> progress = ValueNotifier(
    const ChinaRouteUpdateProgress(stage: ChinaRouteUpdateStage.activating),
  );
}
