import 'package:flutter/material.dart';
import 'package:meow_client/core/widgets/app_notice.dart';
import 'package:meow_client/data/routing/custom_routing_rule.dart';
import 'package:meow_client/features/settings/settings_ui.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/theme/app_theme.dart';
import 'package:meow_client/widgets/progressive_blur_scaffold.dart';

class CustomRoutingRulesPage extends StatefulWidget {
  const CustomRoutingRulesPage({
    super.key,
    required this.currentRules,
    required this.onChanged,
  });

  final List<CustomRoutingRule> currentRules;
  final ValueChanged<List<CustomRoutingRule>> onChanged;

  @override
  State<CustomRoutingRulesPage> createState() => _CustomRoutingRulesPageState();
}

class _CustomRoutingRulesPageState extends State<CustomRoutingRulesPage> {
  late List<CustomRoutingRule> _rules;

  @override
  void initState() {
    super.initState();
    _rules = List<CustomRoutingRule>.of(widget.currentRules);
  }

  @override
  void didUpdateWidget(covariant CustomRoutingRulesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.currentRules, widget.currentRules)) {
      _rules = List<CustomRoutingRule>.of(widget.currentRules);
    }
  }

  void _commit(List<CustomRoutingRule> rules) {
    final normalized = CustomRoutingRule.normalizeCustomRoutingRules(rules);
    setState(() => _rules = normalized);
    widget.onChanged(normalized);
  }

  Future<void> _editRule({int? index}) async {
    final l10n = AppLocalizations.of(context);
    if (index == null && _rules.length >= maxCustomRouteRuleCount) {
      AppNotice.show(
        context,
        l10n.customRoutingRulesLimit(maxCustomRouteRuleCount),
        tone: AppNoticeTone.error,
      );
      return;
    }

    final result = await showDialog<CustomRoutingRule>(
      context: context,
      builder: (context) => _CustomRoutingRuleDialog(
        initialRule: index == null ? null : _rules[index],
      ),
    );
    if (!mounted || result == null) return;

    final duplicateIndex = _rules.indexWhere((rule) => rule.key == result.key);
    if (duplicateIndex >= 0 && duplicateIndex != index) {
      AppNotice.show(
        context,
        l10n.customRoutingRuleDuplicate,
        tone: AppNoticeTone.error,
      );
      return;
    }

    final updated = List<CustomRoutingRule>.of(_rules);
    if (index == null) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    _commit(updated);
  }

  void _moveRule(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _rules.length) return;
    final updated = List<CustomRoutingRule>.of(_rules);
    final rule = updated.removeAt(index);
    updated.insert(target, rule);
    _commit(updated);
  }

  void _deleteRule(int index) {
    final updated = List<CustomRoutingRule>.of(_rules)..removeAt(index);
    _commit(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ProgressiveBlurScaffold(
      appBar: AppBar(title: Text(l10n.customRoutingRulesTitle)),
      body: Theme(
        data: settingsTileTheme(context),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            settingsScreenPadding.left,
            progressiveHeaderTopPadding(context, settingsScreenPadding.top),
            settingsScreenPadding.right,
            appBottomSafePadding(context, settingsScreenPadding.bottom),
          ),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.customRoutingRulesDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: settingsIslandGap),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (_rules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            size: 34,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.customRoutingRulesEmptyTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.customRoutingRulesEmptySubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (var index = 0; index < _rules.length; index++)
                      _CustomRoutingRuleTile(
                        key: ValueKey(_rules[index].key),
                        rule: _rules[index],
                        index: index,
                        count: _rules.length,
                        onEdit: () => _editRule(index: index),
                        onMoveUp: () => _moveRule(index, -1),
                        onMoveDown: () => _moveRule(index, 1),
                        onDelete: () => _deleteRule(index),
                      ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add_rounded),
                    title: Text(l10n.customRoutingRuleAdd),
                    subtitle: Text(l10n.customRoutingRulesCount(_rules.length)),
                    onTap: () => _editRule(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRoutingRuleTile extends StatelessWidget {
  const _CustomRoutingRuleTile({
    super.key,
    required this.rule,
    required this.index,
    required this.count,
    required this.onEdit,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  final CustomRoutingRule rule;
  final int index;
  final int count;
  final VoidCallback onEdit;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final actionColor = rule.action == CustomRouteAction.direct
        ? cs.tertiary
        : cs.primary;
    final actionLabel = rule.action == CustomRouteAction.direct
        ? l10n.customRoutingRuleDirect
        : l10n.customRoutingRuleProxy;

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      leading: SettingsLeadingIcon(
        icon: rule.type == CustomRouteRuleType.domain
            ? Icons.language_rounded
            : Icons.public_rounded,
        color: actionColor,
        size: 38,
      ),
      title: Text(
        rule.value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${rule.type == CustomRouteRuleType.domain ? l10n.customRoutingRuleDomain : l10n.customRoutingRuleIp} · $actionLabel',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onEdit,
      trailing: PopupMenuButton<String>(
        tooltip: l10n.customRoutingRuleActions,
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'up':
              onMoveUp();
            case 'down':
              onMoveDown();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.customRoutingRuleEdit),
            ),
          ),
          PopupMenuItem<String>(
            value: 'up',
            enabled: index > 0,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.arrow_upward_rounded),
              title: Text(l10n.customRoutingRuleMoveUp),
            ),
          ),
          PopupMenuItem<String>(
            value: 'down',
            enabled: index < count - 1,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.arrow_downward_rounded),
              title: Text(l10n.customRoutingRuleMoveDown),
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline_rounded, color: cs.error),
              title: Text(l10n.customRoutingRuleDelete),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomRoutingRuleDialog extends StatefulWidget {
  const _CustomRoutingRuleDialog({this.initialRule});

  final CustomRoutingRule? initialRule;

  @override
  State<_CustomRoutingRuleDialog> createState() =>
      _CustomRoutingRuleDialogState();
}

class _CustomRoutingRuleDialogState extends State<_CustomRoutingRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late CustomRouteRuleType _type;
  late CustomRouteAction _action;
  _ExpandField? _openField;

  void _toggleField(_ExpandField field) {
    setState(() => _openField = _openField == field ? null : field);
  }

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    _type = rule?.type ?? CustomRouteRuleType.domain;
    _action = rule?.action ?? CustomRouteAction.proxy;
    _valueController = TextEditingController(text: rule?.value ?? '');
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String? _validateValue(String? value, AppLocalizations l10n) {
    try {
      CustomRoutingRule.create(
        type: _type,
        value: value ?? '',
        action: _action,
      );
      return null;
    } on FormatException {
      return _type == CustomRouteRuleType.domain
          ? l10n.customRoutingRuleInvalidDomain
          : l10n.customRoutingRuleInvalidIp;
    }
  }

  void _save(AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return;
    try {
      Navigator.of(context).pop(
        CustomRoutingRule.create(
          type: _type,
          value: _valueController.text,
          action: _action,
        ),
      );
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customRoutingRuleInvalidValue)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = widget.initialRule != null;
    return AlertDialog(
      title: Text(
        existing
            ? l10n.customRoutingRuleEditTitle
            : l10n.customRoutingRuleAddTitle,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InlineSelectField<CustomRouteRuleType>(
                labelText: l10n.customRoutingRuleType,
                value: _type,
                expanded: _openField == _ExpandField.type,
                onToggle: () => _toggleField(_ExpandField.type),
                options: [
                  _SelectOption(
                    value: CustomRouteRuleType.domain,
                    label: l10n.customRoutingRuleDomain,
                  ),
                  _SelectOption(
                    value: CustomRouteRuleType.ip,
                    label: l10n.customRoutingRuleIp,
                  ),
                ],
                onChanged: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: _type == CustomRouteRuleType.domain
                      ? l10n.customRoutingRuleDomainLabel
                      : l10n.customRoutingRuleIpLabel,
                  hintText: _type == CustomRouteRuleType.domain
                      ? l10n.customRoutingRuleDomainHint
                      : l10n.customRoutingRuleIpHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => _validateValue(value, l10n),
                onFieldSubmitted: (_) => _save(l10n),
              ),
              const SizedBox(height: 12),
              _InlineSelectField<CustomRouteAction>(
                labelText: l10n.customRoutingRuleTarget,
                value: _action,
                expanded: _openField == _ExpandField.action,
                onToggle: () => _toggleField(_ExpandField.action),
                options: [
                  _SelectOption(
                    value: CustomRouteAction.proxy,
                    label: l10n.customRoutingRuleProxy,
                  ),
                  _SelectOption(
                    value: CustomRouteAction.direct,
                    label: l10n.customRoutingRuleDirect,
                  ),
                ],
                onChanged: (value) => setState(() => _action = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => _save(l10n),
          child: Text(l10n.customRoutingRuleSave),
        ),
      ],
    );
  }
}

/// Which inline selector is currently expanded inside [_CustomRoutingRuleDialog].
enum _ExpandField { type, action }

/// A single selectable option for [_InlineSelectField].
class _SelectOption<T> {
  const _SelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A dropdown replacement that expands inline instead of opening a native
/// popup menu. The closed trigger is an [InputDecorator] identical to the
/// surrounding text fields, and the expanded option list reuses the same
/// input decoration (fill, radius, border, padding), so the popup reads as
/// a visual continuation of the box rather than a detached system menu.
class _InlineSelectField<T> extends StatelessWidget {
  const _InlineSelectField({
    required this.labelText,
    required this.value,
    required this.options,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
  });

  final String labelText;
  final T value;
  final List<_SelectOption<T>> options;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceTheme = theme.extension<AppSurfaceTheme>();
    final borderRadius =
        BorderRadius.circular(surfaceTheme?.smallRadius ?? 16);
    final inputTheme = theme.inputDecorationTheme;
    final currentLabel = options
        .firstWhere((option) => option.value == value,
            orElse: () => options.first)
        .label;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: borderRadius,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: labelText,
                suffixIcon: Icon(
                  expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                ),
              ),
              child: Text(currentLabel),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: inputTheme.fillColor,
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final option in options)
                            InkWell(
                              onTap: () => onChanged(option.value),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(option.label),
                                    ),
                                    if (option.value == value)
                                      Icon(
                                        Icons.check,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
