import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/proxies/latency_measurement_scope.dart';
import 'package:meow_client/features/proxies/proxies_page.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/models/app_view_models.dart';
import 'package:meow_client/models/latency_measurement_mode.dart';

void main() {
  testWidgets(
    'proxy measurement tooltip switches without mixing metric descriptions',
    (tester) async {
      const proxy = AppProxySummary(
        tag: 'node',
        displayName: 'Node',
        countryCode: '',
        type: 'vless',
        server: 'example.test',
        port: 443,
        detailText: 'VLESS',
        ip: '',
        latency: 123,
        latencyFresh: true,
        latencyChecking: false,
        latencyUnavailable: false,
        latencyError: null,
        protocolLabel: 'VLESS',
        endpointLabel: 'example.test:443',
      );
      late AppLocalizations l10n;
      Widget app(LatencyMeasurementMode mode) => MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LatencyMeasurementScope(
          mode: mode,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context);
                return ProxyTile(
                  proxy: proxy,
                  selected: false,
                  onTap: () {},
                  onTestLatency: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(LatencyMeasurementMode.unifiedUrlTest));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message == l10n.proxyLatencyMeasurementDescription,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message == l10n.realUrlLatencyDescription,
        ),
        findsNothing,
      );
      await tester.pumpWidget(app(LatencyMeasurementMode.realUrl));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message == l10n.realUrlLatencyDescription,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message == l10n.proxyLatencyMeasurementDescription,
        ),
        findsNothing,
      );
    },
  );
}
