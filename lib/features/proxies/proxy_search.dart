import 'package:flutter/material.dart';
import 'package:meow_client/models/app_view_models.dart';

/// Localized search UI copy without changing generated l10n sources.
class ProxySearchCopy {
  const ProxySearchCopy._(
    this.title,
    this.hint,
    this.clear,
    this.done,
    this.noResults,
  );
  final String title;
  final String hint;
  final String clear;
  final String done;
  final String noResults;

  factory ProxySearchCopy.of(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
      case 'zh':
        return const ProxySearchCopy._(
          '搜索服务器',
          '名称、协议、国家或地区',
          '清空',
          '完成',
          '未找到匹配的服务器',
        );
      case 'ru':
        return const ProxySearchCopy._(
          'Поиск серверов',
          'Имя, протокол, страна или регион',
          'Очистить',
          'Готово',
          'Подходящие серверы не найдены',
        );
      default:
        return const ProxySearchCopy._(
          'Search servers',
          'Name, protocol, country or region',
          'Clear',
          'Done',
          'No matching servers found',
        );
    }
  }
}

/// Matches user-visible proxy metadata without changing selection or ordering.
bool proxyMatchesSearch(AppProxySummary proxy, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return <String>[
    proxy.displayName,
    proxy.protocolLabel,
    proxy.countryCode,
    proxy.detailText,
    proxy.type,
    proxy.server,
    proxy.endpointLabel,
  ].any((value) => value.toLowerCase().contains(needle));
}

/// Keeps a group visible when any of its children match the search.
bool proxyOrChildMatchesSearch(
  AppProxySummary proxy,
  String query,
  Iterable<AppProxySummary> children,
) =>
    proxyMatchesSearch(proxy, query) ||
    children.any((child) => proxyMatchesSearch(child, query));

/// Owns its controller until the dialog route finishes its exit animation.
class ProxySearchDialog extends StatefulWidget {
  const ProxySearchDialog({super.key, required this.initialQuery});
  final String initialQuery;
  @override
  State<ProxySearchDialog> createState() => _ProxySearchDialogState();
}

class _ProxySearchDialogState extends State<ProxySearchDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = ProxySearchCopy.of(context);
    return AlertDialog(
      title: Text(copy.title),
      content: TextField(
        key: const ValueKey('proxy-search-field'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(hintText: copy.hint),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          key: const ValueKey('proxy-search-clear'),
          onPressed: () => Navigator.of(context).pop(''),
          child: Text(copy.clear),
        ),
        TextButton(
          key: const ValueKey('proxy-search-apply'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(copy.done),
        ),
      ],
    );
  }
}
