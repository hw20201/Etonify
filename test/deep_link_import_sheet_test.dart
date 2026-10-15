import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/app/deep_link_import.dart';
import 'package:meow_client/app/widgets/deep_link_import_sheet.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('generic deep-link sheet shows the URL and import actions', (
    tester,
  ) async {
    const request = DeepLinkImportRequest(
      url: 'https://example.com/subscription',
      name: 'Example subscription',
    );
    const preview = DeepLinkImportPreview(
      sourceUrl: 'https://example.com/subscription',
      resolvedUrl: 'https://example.com/subscription',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) {
                    final l10n = AppLocalizations.of(sheetContext);
                    return DeepLinkImportSheet(
                      request: request,
                      preview: preview,
                      copy: DeepLinkImportCopy.fromContext(sheetContext),
                      l10n: l10n,
                    );
                  },
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(DeepLinkImportSheet)),
    );
    expect(find.text('Example subscription'), findsOneWidget);
    expect(find.text('https://example.com/subscription'), findsOneWidget);
    expect(find.text(l10n.deepLinkImportAction), findsOneWidget);
    expect(find.text(l10n.cancel), findsOneWidget);
    expect(find.text('Happ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
