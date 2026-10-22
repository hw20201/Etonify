import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';
import 'package:meow_client/widgets/country_flag_badge.dart';

/// A compact public-IP capsule that opens a themed, anchored detail card.
class PublicIpPeek extends StatefulWidget {
  const PublicIpPeek({
    super.key,
    required this.controller,
    required this.connected,
    required this.hideIp,
    required this.hapticEnabled,
  });

  final PublicIpController controller;
  final bool connected;
  final bool hideIp;
  final bool hapticEnabled;

  @override
  State<PublicIpPeek> createState() => _PublicIpPeekState();
}

class _PublicIpPeekState extends State<PublicIpPeek>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _capsuleKey = GlobalKey();
  late final AnimationController _panelAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _panelCurve = CurvedAnimation(
    parent: _panelAnimation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.connected && widget.controller.info == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.connected) {
          unawaited(widget.controller.refresh());
        }
      });
    }
  }

  @override
  void didUpdateWidget(PublicIpPeek oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connected &&
        !oldWidget.connected &&
        widget.controller.info == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.connected) {
          unawaited(widget.controller.refresh());
        }
      });
    }
    if (!widget.connected && _expanded) _closePanel();
  }

  @override
  void dispose() {
    _panelAnimation.dispose();
    super.dispose();
  }

  String _displayIp(String ip) {
    if (ip.isEmpty) return AppLocalizations.of(context).notAvailableShort;
    if (!widget.hideIp) return ip;
    final octets = ip.split('.');
    if (octets.length == 4) return '${octets[0]}.${octets[1]}.*.*';
    return ip.length > 8 ? '${ip.substring(0, ip.length ~/ 2)}****' : '****';
  }

  void _togglePanel() {
    if (_expanded) {
      _closePanel();
      return;
    }
    if (widget.hapticEnabled) HapticFeedback.selectionClick();
    setState(() => _expanded = true);
    _portalController.show();
    _panelAnimation.forward(from: 0);
    if (widget.controller.info == null || widget.controller.failed) {
      unawaited(widget.controller.refresh());
    }
  }

  void _closePanel() {
    if (!_expanded) return;
    if (widget.hapticEnabled) HapticFeedback.selectionClick();
    setState(() => _expanded = false);
    unawaited(
      _panelAnimation.reverse().whenComplete(() {
        if (mounted && !_expanded) _portalController.hide();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.connected) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final displayedIp = _displayIp(widget.controller.info?.ip ?? '');
        final accent = theme.colorScheme.primary;
        // Keep the backdrop in the app-wide overlay. The nearest overlay can
        // be bounded/clipped to the home content area, leaving the area below
        // the card undimmed and making the background color visibly change.
        return OverlayPortal(
          overlayLocation: OverlayChildLocation.rootOverlay,
          controller: _portalController,
          overlayChildBuilder: (overlayContext) =>
              _buildOverlay(overlayContext, theme, l10n, accent),
          child: Center(
            child: CompositedTransformTarget(
              key: _capsuleKey,
              link: _layerLink,
              child: Semantics(
                button: true,
                expanded: _expanded,
                hidden: _expanded,
                label: '${l10n.homeOutboundIpExpand}: $displayedIp',
                child: Tooltip(
                  message: _expanded
                      ? l10n.homeOutboundIpCollapse
                      : l10n.homeOutboundIpExpand,
                  child: AnimatedOpacity(
                    key: const ValueKey('outbound-ip-capsule-visibility'),
                    opacity: _expanded ? 0 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: IgnorePointer(
                      ignoring: _expanded,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          key: const ValueKey('outbound-ip-capsule'),
                          onTap: _togglePanel,
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            constraints: const BoxConstraints(
                              minWidth: 150,
                              minHeight: 42,
                              maxWidth: 280,
                            ),
                            padding: const EdgeInsetsDirectional.only(
                              start: 20,
                              end: 13,
                              top: 7,
                              bottom: 7,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh
                                  .withValues(alpha: _expanded ? .52 : .22),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: _expanded ? .88 : .64,
                                ),
                                width: _expanded ? 1.5 : 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(
                                    alpha: _expanded ? .2 : .08,
                                  ),
                                  blurRadius: _expanded ? 22 : 12,
                                  spreadRadius: _expanded ? 1 : 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, .12),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: Text(
                                      displayedIp,
                                      key: ValueKey(displayedIp),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: .1,
                                          ),
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                AnimatedRotation(
                                  key: const ValueKey(
                                    'outbound-ip-capsule-chevron',
                                  ),
                                  turns: _expanded ? .5 : 0,
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    size: 22,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlay(
    BuildContext overlayContext,
    ThemeData theme,
    AppLocalizations l10n,
    Color accent,
  ) {
    final media = MediaQuery.of(overlayContext);
    final cardWidth = math
        .min(560.0, math.max(0.0, media.size.width - 32))
        .toDouble();
    final topInset = media.padding.top + 12;
    final targetObject = _capsuleKey.currentContext?.findRenderObject();
    final targetTop = targetObject is RenderBox && targetObject.hasSize
        ? targetObject.localToGlobal(Offset.zero).dy
        : media.size.height * .68;
    final maxCardHeight = math
        .min(
          media.size.height - topInset - media.padding.bottom - 24,
          math.max(220.0, targetTop - topInset - 20),
        )
        .toDouble();
    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePanel,
              child: AnimatedBuilder(
                animation: _panelCurve,
                builder: (context, _) => ColoredBox(
                  key: const ValueKey('outbound-ip-overlay-backdrop'),
                  color: theme.colorScheme.scrim.withValues(
                    alpha: .12 * _panelCurve.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -10),
            child: AnimatedBuilder(
              animation: _panelCurve,
              builder: (context, child) => FadeTransition(
                opacity: _panelCurve,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .075),
                    end: Offset.zero,
                  ).animate(_panelCurve),
                  child: ScaleTransition(
                    alignment: Alignment.bottomCenter,
                    scale: Tween<double>(
                      begin: .965,
                      end: 1,
                    ).animate(_panelCurve),
                    child: SizeTransition(
                      alignment: Alignment.bottomCenter,
                      sizeFactor: _panelCurve,
                      child: child,
                    ),
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: cardWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxCardHeight),
                    child: _PublicIpDetailsCard(
                      controller: widget.controller,
                      hideIp: widget.hideIp,
                      onClose: _closePanel,
                      accent: accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicIpDetailsCard extends StatelessWidget {
  const _PublicIpDetailsCard({
    required this.controller,
    required this.hideIp,
    required this.onClose,
    required this.accent,
  });

  final PublicIpController controller;
  final bool hideIp;
  final VoidCallback onClose;
  final Color accent;

  String _maskedIp(String ip) {
    if (!hideIp) return ip;
    final octets = ip.split('.');
    if (octets.length == 4) return '${octets[0]}.${octets[1]}.*.*';
    return ip.length > 8 ? '${ip.substring(0, ip.length ~/ 2)}****' : '****';
  }

  String _countryLocation(AppLocalizations l10n, PublicIpInfo info) {
    return info.locationLabel.isEmpty
        ? l10n.notAvailableShort
        : info.locationLabel;
  }

  String _sourceLabel(AppLocalizations l10n, PublicIpSource source) {
    return switch (source) {
      PublicIpSource.ipQuery => l10n.homeOutboundIpSourceIpQuery,
      PublicIpSource.ipApi => l10n.homeOutboundIpSourceIpApi,
      PublicIpSource.ipWho => l10n.homeOutboundIpSourceIpWho,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final currentInfo = controller.info;
        return DecoratedBox(
          key: const ValueKey('outbound-ip-details-card'),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: .72),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? .2 : .12),
                blurRadius: 30,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .32 : .12),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.homeOutboundIpTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.2,
                                ),
                              ),
                              const Gap(3),
                              Text(
                                l10n.homeOutboundIpHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        IconButton.filledTonal(
                          key: const ValueKey('outbound-ip-refresh'),
                          tooltip: controller.canRefresh
                              ? l10n.trafficDashboardPublicIpRefresh
                              : l10n.trafficDashboardPublicIpCooldown,
                          onPressed: controller.canRefresh
                              ? () => unawaited(controller.refresh())
                              : null,
                          visualDensity: VisualDensity.compact,
                          icon: controller.loading
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                        IconButton(
                          key: const ValueKey('outbound-ip-close'),
                          tooltip: l10n.homeOutboundIpCollapse,
                          onPressed: onClose,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    if (currentInfo == null) ...[
                      const Gap(16),
                      _LookupStatus(
                        loading: controller.loading,
                        failed: controller.failed,
                        failureKind: controller.failureKind,
                      ),
                    ] else ...[
                      const Gap(18),
                      _InfoSection(
                        title: l10n.homeOutboundIpBasicSection,
                        rows: [
                          _InfoRowData(
                            l10n.homeOutboundIpCountry,
                            _countryLocation(l10n, currentInfo),
                            leading: CountryFlagBadge(
                              countryCode: currentInfo.countryCode,
                              size: 20,
                            ),
                            allowWrap: true,
                          ),
                          _InfoRowData(
                            l10n.homeOutboundIpAddress,
                            _maskedIp(currentInfo.ip),
                          ),
                        ],
                      ),
                      const Gap(14),
                      _InfoSection(
                        title: l10n.homeOutboundIpNetworkSection,
                        rows: [
                          if (currentInfo.isp.isNotEmpty)
                            _InfoRowData(
                              l10n.homeOutboundIpIsp,
                              currentInfo.isp,
                              allowWrap: true,
                            ),
                          _InfoRowData(
                            l10n.homeOutboundIpOrganization,
                            currentInfo.organization.isEmpty
                                ? l10n.notAvailableShort
                                : currentInfo.organization,
                            allowWrap: true,
                          ),
                          _InfoRowData(
                            l10n.homeOutboundIpAsn,
                            currentInfo.asn.isEmpty
                                ? l10n.notAvailableShort
                                : currentInfo.asn,
                          ),
                          _InfoRowData(
                            l10n.homeOutboundIpSource,
                            _sourceLabel(l10n, currentInfo.source),
                          ),
                        ],
                      ),
                      if (controller.loading) ...[
                        const Gap(12),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      if (controller.failed) ...[
                        const Gap(10),
                        Text(
                          switch (controller.failureKind) {
                            PublicIpFailureKind.unsupportedConfiguration =>
                              l10n.trafficDashboardPublicIpUnsupported,
                            PublicIpFailureKind.notConnected =>
                              l10n.trafficDashboardPublicIpNotConnected,
                            PublicIpFailureKind.timeout =>
                              l10n.trafficDashboardPublicIpTimeout,
                            _ => l10n.trafficDashboardPublicIpError,
                          },
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LookupStatus extends StatelessWidget {
  const _LookupStatus({
    required this.loading,
    required this.failed,
    required this.failureKind,
  });

  final bool loading;
  final bool failed;
  final PublicIpFailureKind? failureKind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: loading
              ? SizedBox.square(
                  key: const ValueKey('loading'),
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Icon(
                  key: ValueKey(failed),
                  failed ? Icons.error_outline_rounded : Icons.public_rounded,
                  color: failed
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  size: 20,
                ),
        ),
        const Gap(10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              failed
                  ? switch (failureKind) {
                      PublicIpFailureKind.unsupportedConfiguration =>
                        l10n.trafficDashboardPublicIpUnsupported,
                      PublicIpFailureKind.notConnected =>
                        l10n.trafficDashboardPublicIpNotConnected,
                      PublicIpFailureKind.timeout =>
                        l10n.trafficDashboardPublicIpTimeout,
                      _ => l10n.trafficDashboardPublicIpError,
                    }
                  : loading
                  ? l10n.homeOutboundIpLoading
                  : l10n.homeOutboundIpUnavailable,
              key: ValueKey((loading, failed)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: failed
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
class _InfoRowData {
  const _InfoRowData(
    this.label,
    this.value, {
    this.leading,
    this.allowWrap = false,
  });

  final String label;
  final String value;
  final Widget? leading;
  final bool allowWrap;
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 7),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: .34,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: .28,
                    ),
                  ),
                _InfoRow(row: rows[index]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.row});

  final _InfoRowData row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        crossAxisAlignment: row.allowWrap
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            flex: 6,
            child: Row(
              crossAxisAlignment: row.allowWrap
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (row.leading != null) ...[row.leading!, const Gap(6)],
                Flexible(
                  child: Text(
                    row.value,
                    maxLines: row.allowWrap ? null : 1,
                    overflow: row.allowWrap
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
