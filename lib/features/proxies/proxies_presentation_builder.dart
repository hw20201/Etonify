import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meow_client/features/proxies/proxies_page.dart';
import 'package:meow_client/features/proxies/latency_measurement_scope.dart';
import 'package:meow_client/models/latency_measurement_mode.dart';
import 'package:meow_client/features/proxies/proxy_panel_shell.dart';
import 'package:meow_client/models/app_view_models.dart';
import 'package:meow_client/models/proxy_runtime_visual_state.dart';
import 'package:meow_client/models/subscription.dart';
import 'package:meow_client/models/url_test_progress.dart';

@immutable
class ProxiesPresentationData {
  const ProxiesPresentationData({
    this.profileId = '',
    required this.proxies,
    required this.groupChildrenByTag,
    required this.selectedTag,
    required this.activeProxy,
    required this.connected,
    this.serverCount = 0,
    this.urlTestInFlight = false,
    this.urlTestInFlightListenable,
    this.urlTestProgressListenable,
    required this.hapticEnabled,
    required this.trafficAvailable,
    required this.downlinkBytesPerSecond,
    required this.uplinkTotalBytes,
    required this.downlinkTotalBytes,
    required this.trafficListenable,
    required this.initialSort,
    required this.progressiveBlurEnabled,
    required this.runtimeStates,
    this.proxyListLoading = false,
    this.latencyMeasurementMode = LatencyMeasurementMode.unifiedUrlTest,
  });

  final String profileId;
  final List<AppProxySummary> proxies;
  final Map<String, List<AppProxySummary>> groupChildrenByTag;
  final String selectedTag;
  final AppProxySummary? activeProxy;
  final bool connected;
  final int serverCount;
  final bool urlTestInFlight;
  final ValueListenable<bool>? urlTestInFlightListenable;
  final ValueListenable<UrlTestProgressState>? urlTestProgressListenable;
  final bool hapticEnabled;
  final bool trafficAvailable;
  final int downlinkBytesPerSecond;
  final int uplinkTotalBytes;
  final int downlinkTotalBytes;
  final ValueListenable<TrafficUiSnapshot> trafficListenable;
  final ProxySort initialSort;
  final bool progressiveBlurEnabled;
  final ProxyRuntimeVisualStore runtimeStates;
  final bool proxyListLoading;
  final LatencyMeasurementMode latencyMeasurementMode;

  double get speedBytesPerSecond =>
      connected && trafficAvailable ? downlinkBytesPerSecond.toDouble() : 0;

  double get trafficBytes => connected && trafficAvailable
      ? (uplinkTotalBytes + downlinkTotalBytes).toDouble()
      : 0;
}

@immutable
class ProxiesPresentationCallbacks {
  const ProxiesPresentationCallbacks({
    required this.changeSort,
    required this.selectProxy,
    required this.runUrlTest,
    this.runProxyUrlTest,
    required this.resolveVisibleProxyLocation,
    required this.outboundForTag,
    required this.loadProxyChainTargetSources,
    required this.loadProxyChainTargetsForSource,
    required this.addProxyChain,
    required this.changeProxyChainDetour,
    required this.renameProxyChain,
    required this.removeProxyChain,
    required this.isProxyChainTag,
  });

  final ValueChanged<ProxySort> changeSort;
  final ValueChanged<String> selectProxy;
  final Future<void> Function() runUrlTest;
  final Future<void> Function(String tag)? runProxyUrlTest;
  final void Function(String tag, ValueGetter<bool> isVisible)
  resolveVisibleProxyLocation;
  final Outbound? Function(String tag) outboundForTag;
  final Future<List<AppProfileSummary>> Function() loadProxyChainTargetSources;
  final Future<List<AppProxySummary>> Function(String subscriptionId)
  loadProxyChainTargetsForSource;
  final Future<void> Function(String detourTag, String targetTag) addProxyChain;
  final Future<void> Function(String chainTag, String detourTag)
  changeProxyChainDetour;
  final Future<void> Function(String chainTag, String name) renameProxyChain;
  final Future<void> Function(String chainTag) removeProxyChain;
  final bool Function(String tag) isProxyChainTag;
}

class ProxiesPresentationBuilder {
  const ProxiesPresentationBuilder({
    required this.data,
    required this.callbacks,
  });

  final ProxiesPresentationData data;
  final ProxiesPresentationCallbacks callbacks;

  Widget build({
    ProxyPanelMetrics? panelMetrics,
    ValueListenable<ProxyPanelMetrics>? panelMetricsListenable,
    ScrollController? scrollController,
    ProxyPanelGestures? panelGestures,
    bool embedded = true,
  }) {
    return LatencyMeasurementScope(
      mode: data.latencyMeasurementMode,
      child: ProxiesPage(
        profileId: data.profileId,
        proxies: data.proxies,
        groupChildrenByTag: data.groupChildrenByTag,
        selectedTag: data.selectedTag,
        activeProxy: data.activeProxy,
        connected: data.connected,
        serverCount: data.serverCount,
        urlTestInFlight: data.urlTestInFlight,
        urlTestInFlightListenable: data.urlTestInFlightListenable,
        urlTestProgressListenable: data.urlTestProgressListenable,
        hapticEnabled: data.hapticEnabled,
        speedBytesPerSecond: data.speedBytesPerSecond,
        trafficBytes: data.trafficBytes,
        trafficListenable: data.trafficListenable,
        initialSort: data.initialSort,
        onSortChanged: callbacks.changeSort,
        progressiveBlurEnabled: data.progressiveBlurEnabled,
        onSelected: callbacks.selectProxy,
        onUrlTest: callbacks.runUrlTest,
        onProxyUrlTest: callbacks.runProxyUrlTest,
        onVisibleProxyNeedsLocation: callbacks.resolveVisibleProxyLocation,
        outboundForTag: callbacks.outboundForTag,
        loadProxyChainTargetSources: callbacks.loadProxyChainTargetSources,
        loadProxyChainTargetsForSource:
            callbacks.loadProxyChainTargetsForSource,
        onAddProxyChain: callbacks.addProxyChain,
        onChangeProxyChainDetour: callbacks.changeProxyChainDetour,
        onRenameProxyChain: callbacks.renameProxyChain,
        onRemoveProxyChain: callbacks.removeProxyChain,
        isProxyChainTag: callbacks.isProxyChainTag,
        runtimeStates: data.runtimeStates,
        loading: data.proxyListLoading,
        embedded: embedded,
        externalNavigationBar: !embedded,
        sheetMetricsListenable: panelMetricsListenable,
        scrollController: scrollController,
        sheetAtMaxExtent: panelMetrics?.atMaxExtent ?? false,
        sheetCanFillScreen: panelMetrics?.canFillScreen ?? false,
        sheetExtent: panelMetrics?.progress ?? 0,
        collapsedSheetExtent: 0,
        expandedHeaderExtent: 1,
        sheetCornerRadius: proxyPanelScreenCornerRadius,
        onHeaderTap: panelGestures?.onHeaderTap,
      ),
    );
  }
}
