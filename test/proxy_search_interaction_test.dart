import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/proxies/proxies_page.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/models/app_view_models.dart';

void main() {
  Widget app({
    bool embedded = false,
    String profile = 'a',
    ValueChanged<String>? select,
    bool group = false,
  }) {
    final tokyo = proxy('tokyo', '东京节点', 'JP');
    final hk = proxy('hk', '香港节点', 'HK');
    final auto = proxy('auto', '自动组', '', group: true);
    return MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ProxiesPage(
          profileId: profile,
          proxies: group ? [auto, tokyo] : [tokyo, hk],
          groupChildrenByTag: group
              ? {
                  'auto': [hk],
                }
              : const {},
          selectedTag: 'tokyo',
          activeProxy: null,
          connected: false,
          serverCount: 2,
          progressiveBlurEnabled: false,
          onSelected: select ?? (_) {},
          onUrlTest: () async {},
          embedded: embedded,
          sheetAtMaxExtent: true,
          sheetCanFillScreen: true,
          sheetExtent: 1,
          hapticEnabled: false,
        ),
      ),
    );
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.tap(find.byKey(const ValueKey('proxy-search-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('proxy-search-field')),
      query,
    );
    await tester.tap(find.byKey(const ValueKey('proxy-search-apply')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final embedded in [false, true]) {
    testWidgets(
      'search filters, reports no results and clears; embedded=$embedded',
      (tester) async {
        final selected = <String>[];
        await tester.pumpWidget(app(embedded: embedded, select: selected.add));
        await tester.pumpAndSettle();
        expect(find.text('东京节点'), findsOneWidget);
        await search(tester, '香港');
        expect(find.text('香港节点'), findsOneWidget);
        expect(find.text('东京节点'), findsNothing);
        expect(selected, isEmpty);
        await search(tester, 'NO-SUCH-SERVER');
        expect(find.text('未找到匹配的服务器'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('proxy-search-open')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('proxy-search-clear')));
        await tester.pumpAndSettle();
        expect(find.text('东京节点'), findsOneWidget);
        expect(find.text('香港节点'), findsOneWidget);
        await search(tester, 'hK');
        await tester.tap(find.text('香港节点'));
        await tester.pumpAndSettle();
        expect(selected, ['hk']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'profile change resets stale query and dialog cancel retains it',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await search(tester, '香港');
      await tester.tap(find.byKey(const ValueKey('proxy-search-open')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('proxy-search-field')),
        'wrong',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('香港节点'), findsOneWidget);
      expect(find.text('东京节点'), findsNothing);
      await tester.pumpWidget(app(profile: 'b'));
      await tester.pumpAndSettle();
      expect(find.text('东京节点'), findsOneWidget);
      expect(find.text('香港节点'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('child metadata keeps its group discoverable and expandable', (
    tester,
  ) async {
    await tester.pumpWidget(app(group: true));
    await tester.pumpAndSettle();
    await search(tester, '香港');
    expect(find.text('自动组'), findsOneWidget);
    expect(find.text('东京节点'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('proxy-open-group-auto')));
    await tester.pumpAndSettle();
    expect(find.text('香港节点'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AppProxySummary proxy(
  String tag,
  String name,
  String country, {
  bool group = false,
}) => AppProxySummary(
  tag: tag,
  displayName: name,
  countryCode: country,
  type: group ? 'selector' : 'vless',
  server: '$tag.example.invalid',
  port: 443,
  detailText: 'TLS',
  ip: '',
  latency: 45,
  latencyFresh: true,
  latencyChecking: false,
  latencyUnavailable: false,
  latencyError: null,
  protocolLabel: 'VLESS',
  endpointLabel: '$tag.example.invalid:443',
  isGroup: group,
  childCount: group ? 1 : 0,
  childTags: group ? const ['hk'] : const [],
);
