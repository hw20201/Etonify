import 'package:flutter/material.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/models/home_navigation_mode.dart';

/// Opt-in navigation experiment. The original draggable panel remains the
/// default; this shell only owns presentation, never VPN or selection state.
class ExperimentalHomeShell extends StatefulWidget {
  const ExperimentalHomeShell({
    super.key,
    required this.mode,
    required this.homeBuilder,
    required this.proxiesBuilder,
    required this.settingsBuilder,
    required this.onProxiesRequested,
    this.onTabChanged,
  });

  final HomeNavigationMode mode;
  final WidgetBuilder homeBuilder;
  final WidgetBuilder proxiesBuilder;
  final WidgetBuilder settingsBuilder;
  final VoidCallback onProxiesRequested;
  final ValueChanged<int>? onTabChanged;

  @override
  State<ExperimentalHomeShell> createState() => _ExperimentalHomeShellState();
}

class _ExperimentalHomeShellState extends State<ExperimentalHomeShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  void _select(int value) {
    if (_index == value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (value == 1) widget.onProxiesRequested();
    setState(() {
      _index = value;
      _visited.add(value);
    });
    widget.onTabChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final floating = widget.mode == HomeNavigationMode.floating;
    final builders = [
      widget.homeBuilder,
      widget.proxiesBuilder,
      widget.settingsBuilder,
    ];
    final bar = NavigationBar(
      key: const ValueKey('experimental-navigation-bar'),
      selectedIndex: _index,
      onDestinationSelected: _select,
      height: 68,
      backgroundColor: floating ? cs.surfaceContainerHigh : cs.surface,
      elevation: 0,
      destinations: [
        NavigationDestination(
          key: const ValueKey('experimental-tab-home'),
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.homeTab,
        ),
        NavigationDestination(
          key: const ValueKey('experimental-tab-proxies'),
          icon: const Icon(Icons.dns_outlined),
          selectedIcon: const Icon(Icons.dns_rounded),
          label: l10n.proxiesTab,
        ),
        NavigationDestination(
          key: const ValueKey('experimental-tab-settings'),
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: l10n.settingsTitle,
        ),
      ],
    );
    return PopScope<void>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) _select(0);
      },
      child: Scaffold(
        // Reserve actual bar height instead of covering lists or the IP overlay.
        body: IndexedStack(
          index: _index,
          children: List.generate(builders.length, (index) {
            if (!_visited.contains(index)) return const SizedBox.shrink();
            return TickerMode(
              enabled: index == _index,
              child: ExcludeFocus(
                excluding: index != _index,
                child: Builder(builder: builders[index]),
              ),
            );
          }),
        ),
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : floating
            ? SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: cs.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withValues(alpha: .10),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: MediaQuery.removePadding(
                          context: context,
                          removeBottom: true,
                          child: bar,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : bar,
      ),
    );
  }
}
