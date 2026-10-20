import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/experimental_home_shell.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/models/home_navigation_mode.dart';

void main() {
  Widget app(
    HomeNavigationMode mode, {
    VoidCallback? onRequested,
    double keyboard = 0,
  }) {
    return MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboard)),
        child: ExperimentalHomeShell(
          mode: mode,
          homeBuilder: (_) => const Text('home-content'),
          proxiesBuilder: (_) => const _SearchProbe(),
          settingsBuilder: (_) => const Text('settings-content'),
          onProxiesRequested: onRequested ?? () {},
        ),
      ),
    );
  }

  for (final mode in [HomeNavigationMode.floating, HomeNavigationMode.docked]) {
    testWidgets('$mode switches tabs, retains state, returns to home', (
      tester,
    ) async {
      var requests = 0;
      await tester.pumpWidget(app(mode, onRequested: () => requests++));
      expect(find.text('home-content'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const ValueKey('experimental-tab-proxies')));
      await tester.pumpAndSettle();
      expect(requests, 1);
      await tester.enterText(find.byType(TextField), '香港');
      await tester.tap(find.byKey(const ValueKey('experimental-tab-settings')));
      await tester.pumpAndSettle();
      expect(find.text('settings-content'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const ValueKey('experimental-tab-proxies')));
      await tester.pumpAndSettle();
      expect(find.text('香港'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home-content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keyboard hides navigation without throwing away page state', (
    tester,
  ) async {
    await tester.pumpWidget(app(HomeNavigationMode.floating, keyboard: 300));
    expect(
      find.byKey(const ValueKey('experimental-navigation-bar')),
      findsNothing,
    );
    expect(find.text('home-content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact width and large Chinese labels fit', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(HomeNavigationMode.floating));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}

class _SearchProbe extends StatefulWidget {
  const _SearchProbe();
  @override
  State<_SearchProbe> createState() => _SearchProbeState();
}

class _SearchProbeState extends State<_SearchProbe> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Material(child: TextField(controller: controller));
}
