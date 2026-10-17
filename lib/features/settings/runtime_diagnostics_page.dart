import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meow_client/core/widgets/app_notice.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/logging/runtime_diagnostic_log.dart';
import 'package:meow_client/singbox/singbox_runtime.dart';
import 'package:meow_client/widgets/progressive_blur_scaffold.dart';

class RuntimeDiagnosticsPage extends StatelessWidget {
  const RuntimeDiagnosticsPage({super.key});

  Future<void> _export(BuildContext context) async {
    final output = RuntimeDiagnosticLog.dump();
    if (output.isEmpty) {
      AppNotice.show(
        context,
        AppLocalizations.of(context).runtimeDiagnosticsEmpty,
        tone: AppNoticeTone.warning,
      );
      return;
    }
    String? exportUri;
    try {
      exportUri = await SingboxRuntime.instance.exportLogs(
        content: output,
        suggestedName:
            'etonify-runtime-diagnostics-${DateTime.now().millisecondsSinceEpoch}.txt',
      );
    } catch (_) {
      exportUri = null;
    }
    if (!context.mounted) return;
    AppNotice.show(
      context,
      exportUri == null
          ? AppLocalizations.of(context).runtimeDiagnosticsExportFailed
          : AppLocalizations.of(context).runtimeDiagnosticsSaved(exportUri),
      tone: exportUri == null ? AppNoticeTone.error : AppNoticeTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ProgressiveBlurScaffold(
      appBar: AppBar(
        title: Text(l10n.runtimeDiagnosticsTitle),
        actions: [
          IconButton(
            key: const ValueKey('runtime-diagnostics-export'),
            tooltip: l10n.runtimeDiagnosticsExport,
            onPressed: () => unawaited(_export(context)),
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            key: const ValueKey('runtime-diagnostics-clear'),
            tooltip: l10n.runtimeDiagnosticsClear,
            onPressed: RuntimeDiagnosticLog.clear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: .55,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                l10n.runtimeDiagnosticsDescription,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<RuntimeDiagnosticEntry>>(
              valueListenable: RuntimeDiagnosticLog.entries,
              builder: (context, entries, _) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.runtimeDiagnosticsEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  key: const ValueKey('runtime-diagnostics-entries'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final entry = entries[entries.length - index - 1];
                    final color = switch (entry.level) {
                      RuntimeDiagnosticLevel.error => theme.colorScheme.error,
                      RuntimeDiagnosticLevel.warning =>
                        theme.colorScheme.tertiary,
                      RuntimeDiagnosticLevel.info =>
                        theme.colorScheme.onSurfaceVariant,
                    };
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        entry.format(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
