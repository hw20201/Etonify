import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/settings/battery_optimization_tile.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

void main() {
  const channel = MethodChannel('meow_client/battery_optimization');
  TestWidgetsFlutterBinding.ensureInitialized();
  var exempt = false;
  var opens = 0;
  var fail = false;
  setUp(() {
    exempt = false;
    opens = 0;
    fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (fail) throw PlatformException(code: 'unavailable');
          switch (call.method) {
            case 'getStatus':
              return exempt ? 'exempt' : 'restricted';
            case 'openSettings':
              opens++;
              return true;
            default:
              throw MissingPluginException();
          }
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> mount(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: BatteryOptimizationTile()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reads actual exemption after return, not a saved switch value', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Battery optimization'), findsOneWidget);
    expect(find.textContaining('Restricted'), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(find.textContaining('Restricted'), findsOneWidget);
    exempt = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('Unrestricted'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('platform errors stay understandable and do not crash', (
    tester,
  ) async {
    fail = true;
    await mount(tester, locale: const Locale('ru'));
    expect(find.text('Оптимизация батареи'), findsOneWidget);
    expect(find.textContaining('Недоступно'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing system screen reports failure without claiming exemption',
    (tester) async {
      await mount(tester);
      fail = true;
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not open'), findsOneWidget);
      expect(find.textContaining('Unrestricted'), findsNothing);
    },
  );
}
