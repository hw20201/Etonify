import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:meow_client/app/deep_link_import.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

enum DeepLinkImportDecision { import }

class DeepLinkImportCopy {
  const DeepLinkImportCopy({
    required this.title,
    required this.message,
    required this.nameLabel,
    required this.importAction,
    required this.importedTextBuilder,
    this.alreadyExistsTextBuilder,
  });

  factory DeepLinkImportCopy.fromContext(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DeepLinkImportCopy(
      title: l10n.deepLinkImportTitle,
      message: l10n.deepLinkImportMessage,
      nameLabel: l10n.deepLinkImportNameLabel,
      importAction: l10n.deepLinkImportAction,
      importedTextBuilder: l10n.deepLinkImportSuccess,
      alreadyExistsTextBuilder: l10n.deepLinkImportAlreadyExists,
    );
  }

  final String title;
  final String message;
  final String nameLabel;
  final String importAction;
  final String Function(String name) importedTextBuilder;
  final String Function(String name)? alreadyExistsTextBuilder;

  String imported(String name) => importedTextBuilder(name);

  String alreadyExists(String name) =>
      alreadyExistsTextBuilder?.call(name) ??
      'Subscription "$name" is already added';
}

class DeepLinkImportPreview {
  const DeepLinkImportPreview({
    required this.sourceUrl,
    required this.resolvedUrl,
  });

  final String sourceUrl;
  final String resolvedUrl;

  static Future<DeepLinkImportPreview> build(
    DeepLinkImportRequest request,
  ) async {
    return DeepLinkImportPreview(
      sourceUrl: request.url,
      resolvedUrl: request.url,
    );
  }
}

class DeepLinkImportSheet extends StatelessWidget {
  const DeepLinkImportSheet({
    super.key,
    required this.request,
    required this.preview,
    required this.copy,
    required this.l10n,
  });

  final DeepLinkImportRequest request;
  final DeepLinkImportPreview preview;
  final DeepLinkImportCopy copy;
  final AppLocalizations l10n;

  String _summarizeUrl(String value) {
    if (value.length <= 72) {
      return value;
    }
    return '${value.substring(0, 72)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = request.name;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.title, style: theme.textTheme.titleLarge),
                      const Gap(12),
                      Text(copy.message, style: theme.textTheme.bodyLarge),
                      const Gap(16),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (name != null && name.isNotEmpty) ...[
                                  Text(
                                    copy.nameLabel,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const Gap(4),
                                  Text(name, style: theme.textTheme.titleSmall),
                                  const Gap(12),
                                ],
                                Text(
                                  l10n.subscriptionUrl,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Gap(4),
                                SelectableText(
                                  _summarizeUrl(preview.resolvedUrl),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if (preview.sourceUrl !=
                                    preview.resolvedUrl) ...[
                                  const Gap(12),
                                  Text(
                                    l10n.deepLinkImportSourceLabel,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const Gap(4),
                                  SelectableText(
                                    _summarizeUrl(preview.sourceUrl),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(DeepLinkImportDecision.import),
                      child: Text(copy.importAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
