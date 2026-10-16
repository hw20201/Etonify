// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get coreConfigActive => '活跃';

  @override
  String get coreConfigUntrackedDescription => '核心正在运行。本次应用会话没有记录其配置的启动情况。';

  @override
  String get experimentalNetworkSection => '网络';

  @override
  String get experimentalSelectionSection => '服务器选择';

  @override
  String get experimentalMemorySection => '内存';

  @override
  String get subscriptionCustomInterval => '自定义间隔';

  @override
  String get subscriptionIntervalValue => '间隔';

  @override
  String get subscriptionIntervalHours => '小时';

  @override
  String get subscriptionIntervalDays => '天';

  @override
  String get subscriptionIntervalError => '请输入 1 小时到 365 天之间的整数。';

  @override
  String get subscriptionShareGroup => '分享分组';

  @override
  String get subscriptionShareFailed => '无法分享服务器或分组。所需的代理可能不可用。刷新配置后重试。';

  @override
  String get subscriptionGroupAutomatic => '自动选择';

  @override
  String get subscriptionGroupSelector => '服务器分组';

  @override
  String get subscriptionExportJson => '导出 JSON';

  @override
  String get subscriptionAllServers => '所有服务器';

  @override
  String get subscriptionAdvancedSettings => '高级设置';

  @override
  String get subscriptionSearchServers => '按名称、协议或地址搜索';

  @override
  String get subscriptionClearSearch => '清除搜索';

  @override
  String get subscriptionNoServersFound => '未找到服务器';

  @override
  String get subscriptionServersLoadFailed => '无法加载服务器列表，请重试。';

  @override
  String get subscriptionExportFailed => '无法导出配置。';

  @override
  String get subscriptionServersChanged => '该服务器已从配置中移除。请重新打开列表。';

  @override
  String get subscriptionRefreshInterval => '刷新间隔';

  @override
  String get subscriptionMoveUp => '上移';

  @override
  String get subscriptionLocalFile => '已导入文件';

  @override
  String get subscriptionCopy => '复制';

  @override
  String get subscriptionErrorOffline => '无网络连接。请连接 Wi-Fi 或移动数据后重试。';

  @override
  String get subscriptionBackgroundTitle => '后台更新订阅';

  @override
  String get subscriptionBackgroundDescription => '仅限已启用自动更新的订阅。更改将在下次打开应用时生效。';

  @override
  String get autoConnectOnLaunchTitle => '启动时连接';

  @override
  String get autoConnectOnLaunchDescription => '打开应用时，使用上次选择的服务器启动 VPN。';

  @override
  String get quickSettingsTileTitle => '在快捷设置中添加 VPN 磁贴';

  @override
  String get quickSettingsTileDescription => '无需打开应用即可连接或断开。';

  @override
  String get quickSettingsTileManualHint => '编辑快捷设置，将 Etonify 磁贴拖到合适位置。';

  @override
  String get quickSettingsTileAlreadyAdded => 'Etonify 磁贴已添加。';

  @override
  String get quickSettingsTileAddFailed => '无法添加磁贴，请从快捷设置编辑模式手动添加。';

  @override
  String get subscriptionReportTitle => '订阅更新';

  @override
  String get subscriptionReportEmpty => '暂无自动更新记录。';

  @override
  String get subscriptionReportDetails => '详情';

  @override
  String get subscriptionReportSuccess => '已更新';

  @override
  String get subscriptionReportBackground => '在后台下载';

  @override
  String subscriptionReportSummary(int success, int failed) {
    return '已更新配置：$success。错误：$failed。';
  }

  @override
  String get subscriptionBackgroundSaveError => '无法安排后台更新。请重试。';

  @override
  String get coreSettingsNatIndependent => '不依赖目标地址';

  @override
  String get coreSettingsNatAddress => '按地址';

  @override
  String get coreSettingsNatAddressPort => '按地址和端口';

  @override
  String get coreSettingsChooseServer => '选择服务器';

  @override
  String get coreSettingsMuxConnections => '最大连接数';

  @override
  String get coreSettingsMuxMinStreams => '新建连接前的流数量';

  @override
  String get coreSettingsTitle => '核心设置';

  @override
  String get coreSettingsNoticeTitle => '更改这些设置之前';

  @override
  String get coreSettingsNotice =>
      '这些参数通常无需修改。不当的数值可能导致连接中断，或增加耗电与流量消耗。请一次只修改一个参数，点击右上角的重置按钮可恢复默认值。';

  @override
  String get coreSettingsContinue => '继续';

  @override
  String get coreSettingsDefault => '默认';

  @override
  String get coreSettingsOff => '关闭';

  @override
  String get coreSettingsOn => '开';

  @override
  String get coreSettingsManual => '手动';

  @override
  String get coreSettingsAuto => '自动';

  @override
  String get coreSettingsApply => '应用';

  @override
  String get coreSettingsApplying => '正在检查并应用……';

  @override
  String get coreSettingsFailed => '无法应用设置，已保留之前的设置。请查看日志，或等待当前连接操作完成。';

  @override
  String get coreSettingsSaved => '核心设置已应用';

  @override
  String get coreSettingsReset => '重置核心设置';

  @override
  String get coreSettingsResetBody => '仅重置此部分？订阅、DNS、路由及其他设置不会改变。VPN 可能会重新连接。';

  @override
  String get coreSettingsDiscard => '放弃更改？';

  @override
  String get coreSettingsDiscardBody => '更改尚未应用。';

  @override
  String get coreSettingsDiscardAction => '放弃';

  @override
  String get coreSettingsNetwork => '网络';

  @override
  String get coreSettingsStrategy => '网络策略';

  @override
  String get coreSettingsStrategyHelp =>
      '默认保留核心行为。Hybrid 并行尝试可用网络，不会叠加速度，可能消耗蜂窝数据。Fallback 在延迟后尝试备用网络。提供商显式指定的网络或接口设置优先。网络可用性取决于 Android。';

  @override
  String get coreSettingsPrimaryNetwork => '首选网络';

  @override
  String get coreSettingsFallbackNetwork => '备用网络';

  @override
  String get coreSettingsNetworkHelp =>
      '自动表示由核心选择。选择网络不会打开 Wi-Fi 或移动数据。请勿将首选和备用角色设为同一个显式网络。';

  @override
  String get coreSettingsCellular => '移动网络';

  @override
  String get coreSettingsFallbackDelay => '回退延迟，毫秒';

  @override
  String get coreSettingsFallbackDelayHelp => '尝试备用网络前等待的时间。设为 0 则使用核心默认值。';

  @override
  String get coreSettingsConnections => '连接';

  @override
  String get coreSettingsConnectTimeout => '连接超时，秒';

  @override
  String get coreSettingsConnectTimeoutHelp =>
      '代理套接字连接的最长耗时，不含 URLTest 超时。0 表示保留订阅或核心的默认值。手动设置的值会覆盖适用代理的拨号设置；中转链路中的节点使用其传输层所属方的设置。';

  @override
  String get coreSettingsKeepAliveHelp =>
      'TCP 保活会检查空闲的 TCP 连接。它不能提速，也不会影响 QUIC。默认保留服务商的设置。较短的间隔可能会增加耗电。';

  @override
  String get coreSettingsKeepAlivePeriod => '检查前的空闲时间（秒）';

  @override
  String get coreSettingsKeepAliveInterval => '检测间隔（秒）';

  @override
  String get coreSettingsUdpFragment => 'UDP 分片';

  @override
  String get coreSettingsUdpFragmentHelp =>
      '允许或禁止出站 UDP 套接字的 IP 分片。这不是 TLS 分片。默认保留订阅或核心的设置。分片的数据包可能被网络丢弃。';

  @override
  String get coreSettingsNat => 'UDP / NAT';

  @override
  String get coreSettingsNatInactive => '仅在启用 VPN 入站时可用。';

  @override
  String get coreSettingsMapping => 'UDP 映射';

  @override
  String get coreSettingsMappingHelp =>
      '控制 UDP 映射是在不同目标之间共享，还是按目标地址和端口隔离。默认由核心决定。更严格的模式可能会影响通话和游戏。';

  @override
  String get coreSettingsFiltering => 'UDP 过滤';

  @override
  String get coreSettingsFilteringHelp =>
      '控制哪些远端可以通过已有的 UDP 映射发送数据包：任意地址、已联系过的地址，或已联系过的地址和端口。这不能替代路由或防泄漏保护。';

  @override
  String get coreSettingsNatMax => 'UDP 会话数上限';

  @override
  String get coreSettingsNatMaxHelp =>
      '0 表示使用核心的自动限制。过高的限制会占用更多内存，过低的限制可能中断繁忙的 UDP 流量。除非有特定原因，否则请保持自动。';

  @override
  String get coreSettingsUdpTimeout => 'UDP 空闲超时，秒';

  @override
  String get coreSettingsUdpTimeoutHelp =>
      '在指定空闲时长后清除 UDP 会话。0 表示使用核心默认值。过短的超时可能在数据包间隙中断通话或游戏。';

  @override
  String get coreSettingsAdvanced => '高级';

  @override
  String get coreSettingsTlsTimeout => 'TLS 握手超时，秒';

  @override
  String get coreSettingsTlsTimeoutHelp =>
      '受支持的 TCP 代理上允许的 TLS 握手时间。不影响证书校验或 QUIC 握手。0 表示保留订阅或核心设置。';

  @override
  String get coreSettingsMux => '多路复用';

  @override
  String get coreSettingsMuxHelp =>
      '设置仅应用于当前订阅中的一台服务器。「自动」会保留显式的 sing-box 多路复用设置，否则保持关闭。「自动」不会检测服务器支持情况。Xray Mux 与 XHTTP xmux 是独立机制。分组内的成员保留其提供商设置。';

  @override
  String get coreSettingsMuxServer => '服务器';

  @override
  String get coreSettingsMuxNoServer => '当前订阅中没有可用的单个服务器';

  @override
  String get coreSettingsMuxMode => '模式';

  @override
  String get coreSettingsMuxInheritedOn => '已启用 · 由订阅设置';

  @override
  String get coreSettingsMuxInheritedOff => '关闭 · 由订阅设置';

  @override
  String get coreSettingsMuxNotSet => '关闭 · 未配置';

  @override
  String get coreSettingsMuxOverrideTitle => '覆盖服务器设置？';

  @override
  String get coreSettingsMuxOverrideBody =>
      '服务器必须支持 sing-box 多路复用。不兼容的协议或填充设置可能导致无法连接。此本地覆盖仅替换该服务器的订阅多路复用设置。「自动」将恢复原始设置。';

  @override
  String get coreSettingsMuxProtocol => '多路复用协议';

  @override
  String get coreSettingsMuxStreams => '每连接流数';

  @override
  String get coreSettingsMuxStreamsHelp =>
      '每个连接在打开新连接之前的最大流数。使用 max_streams，不含冲突的 max_connections 与 min_streams 设置。数值越大不一定越快。';

  @override
  String get coreSettingsMuxPaddingHelp => '为多路复用流量添加填充。需要服务器支持；它不是通用的绕过手段。';

  @override
  String get coreSettingsInputRange => '请输入显示范围内的整数。';

  @override
  String get coreSettingsSameNetwork => '请选择不同的首选和备用网络，或选择自动。';

  @override
  String get subscriptionErrorHwid =>
      '无法获取有效的 HWID。自定义 ID 必须包含 10 到 64 个拉丁字母、数字、= 或 - 字符。';

  @override
  String get subscriptionErrorHwidRequired =>
      '提供商因 HWID 拒绝了请求。请确认该订阅允许发送 HWID。若已启用，请联系提供商。';

  @override
  String get subscriptionErrorDeviceLimitReached =>
      '该订阅已达到设备数量上限。请在服务商的账号或机器人中删除旧设备，或联系服务商。';

  @override
  String get sendHwidToProvidersTitle => '向服务商发送 HWID';

  @override
  String get sendHwidToProvidersDescription =>
      '启用后，获取所有订阅时将发送设备 ID、型号和系统版本。禁用后，仍以各订阅的单独权限为准。';

  @override
  String get hwidDefaultEnabledNoticeTitle => 'HWID 发送';

  @override
  String get hwidDefaultEnabledNoticeMessage =>
      '默认启用 HWID 发送。许多服务商需要设备 ID 才能发放和运行订阅。\n\n你可以随时关闭：设置 -> 通用。';

  @override
  String get hwidDefaultEnabledNoticeAction => '知道了';

  @override
  String get autoCheckServersTitle => '自动检测所有服务器';

  @override
  String get autoCheckServersDescription =>
      '在连接、网络切换和选择代理时检查完整列表。即使关闭此项，仍会检查所选服务器。';

  @override
  String get autoCheckDisabledNoticeTitle => '自动服务器检查';

  @override
  String get autoCheckDisabledNoticeMessage =>
      '自动全列表检测已关闭。连接或切换网络后会检测所选服务器；选择自动分组时仅检测其成员一次，全局自动检测仍保持关闭。「最快」模式会在选择延迟最低的服务器之前，检测全列表中缺失或过期的延迟结果。可点击闪电图标手动检测列表。';

  @override
  String get autoCheckDisabledNoticeAction => '知道了';

  @override
  String proxiesProgressWorking(int working, int total) {
    return '可用 $working / $total';
  }

  @override
  String proxiesProgressTested(int tested, int total) {
    return '已测试 $tested / $total';
  }

  @override
  String proxiesProgressSkipped(int count) {
    return '已排除：$count';
  }

  @override
  String get proxiesProgressSkippedExplanation =>
      '这些服务器不在当前核心的检测队列中，不计为检测失败。不支持或无效的配置可能已被排除，详情见启动日志。';

  @override
  String get proxiesCheckPaused => '检查已暂停';

  @override
  String proxiesTotal(int total) {
    return '共 $total';
  }

  @override
  String get profiles => '配置';

  @override
  String get close => '关闭';

  @override
  String get homeTab => '首页';

  @override
  String get proxiesTab => '代理';

  @override
  String get proxiesTitle => '代理';

  @override
  String get proxySwitching => '切换中';

  @override
  String get proxyUnavailable => '不可用';

  @override
  String get proxyLatencyNoResult => '无结果';

  @override
  String get proxyLatencyNoResultDescription => '此服务器暂无延迟测试结果。';

  @override
  String get proxySelectorTitle => '选择器';

  @override
  String get proxyLowestName => '最低';

  @override
  String get proxyAutomaticSelectionLabel => '自动选择';

  @override
  String get proxyChainLabel => '链式';

  @override
  String get proxyChainAddTitle => '添加代理链';

  @override
  String get proxyChainAddTile => '添加代理链';

  @override
  String get proxyChainChangeFirstHop => '更换首个代理';

  @override
  String get proxyChainRenameAction => '重命名';

  @override
  String get proxyChainRenameTitle => '重命名代理链';

  @override
  String get proxyChainRemoveAction => '删除代理链';

  @override
  String get proxyChainNameLabel => '名称';

  @override
  String get proxyChainFirstHopLabel => '第一跳代理';

  @override
  String get proxyChainExitLabel => '出口代理';

  @override
  String get proxyChainNothingFound => '未找到';

  @override
  String get proxyChainSaveAction => '保存';

  @override
  String get shareProxyTitle => '分享';

  @override
  String get shareProxyLinkLabel => '分享链接';

  @override
  String get shareSingboxOutboundLabel => 'sing-box 出站';

  @override
  String copiedToClipboard(String label) {
    return '$label 已复制';
  }

  @override
  String get unavailableForThisType => '此类型不可用';

  @override
  String get sort => '排序';

  @override
  String get sortByDefault => '订阅源顺序';

  @override
  String get sortByLatency => '按延迟';

  @override
  String get sortByWorking => '仅可用';

  @override
  String get sortByName => '按名称';

  @override
  String get sortByCountry => '按国家/地区';

  @override
  String get settingsTitle => '设置';

  @override
  String get generalSectionTitle => '通用';

  @override
  String get inboundTitle => '入站';

  @override
  String get dnsTitle => 'DNS';

  @override
  String get whitelistTitle => '白名单';

  @override
  String get whitelistSubtitle => '预留路由工具';

  @override
  String get experimentalTitle => '实验性功能';

  @override
  String get securityTitle => '安全';

  @override
  String get securitySubtitle => 'TLS 证书与连接验证';

  @override
  String get securityTlsSectionTitle => 'TLS 证书';

  @override
  String get securityBackupSectionTitle => '订阅备份与恢复';

  @override
  String get securityBackupToLocalTitle => '加密备份订阅到本地';

  @override
  String get securityBackupToLocalSubtitle => '将订阅及服务器信息加密后导出到本地文件，需要设置备份密码。';

  @override
  String get securityRestoreFromLocalTitle => '从本地恢复订阅';

  @override
  String get securityRestoreFromLocalSubtitle => '导入此前导出的加密 Etonify 订阅备份。';

  @override
  String get securityUntrustedProxyCertificatesTitle => '允许不受信任的代理证书';

  @override
  String get securityUntrustedProxyCertificatesSubtitle =>
      '连接到使用自签名、过期或其他不受信任证书的代理服务器。这会削弱对连接劫持的防护。';

  @override
  String get securityUntrustedSubscriptionCertificatesTitle => '允许不受信任的订阅证书';

  @override
  String get securityUntrustedSubscriptionCertificatesSubtitle =>
      '即使网站证书无法验证，也更新 HTTPS 订阅。订阅链接和内容可能被拦截或替换。';

  @override
  String get securityConfirmProxyTitle => '允许不受信任的代理证书？';

  @override
  String get securityConfirmProxyMessage => '将为所有 TLS 代理连接禁用证书验证。仅在信任该配置时启用。';

  @override
  String get securityConfirmSubscriptionTitle => '允许不受信任的订阅证书？';

  @override
  String get securityConfirmSubscriptionMessage =>
      '更新 HTTPS 订阅期间将禁用证书校验。订阅 URL 和内容可能被拦截或替换。';

  @override
  String get securityAllowAction => '允许';

  @override
  String get experimentalSubtitle => '多路径、Fast Open 与连接切换行为';

  @override
  String get logsTitle => '日志';

  @override
  String get logsSubtitle => '生成的 sing-box 配置和应用事件';

  @override
  String get urlTestTitle => '服务器检测';

  @override
  String get urlTestNotReadyMessage => '连接仍在准备中，请几秒后再检查。';

  @override
  String get urlTestSubtitle => '延迟检测与自动选择服务器';

  @override
  String get vpnInTitle => 'VPN 接入';

  @override
  String get proxyInTitle => '代理入口';

  @override
  String get dnsDirectTitle => '直连';

  @override
  String get dnsProxyTitle => '经由代理';

  @override
  String get aboutSectionTitle => '关于';

  @override
  String get aboutSectionSubtitle => '版本、贡献者、帮助与诊断。';

  @override
  String get aboutHeroSubtitle => '一款为 Android 打造的 VPN 客户端：快速、易懂，日常使用稳定可靠。';

  @override
  String get aboutContributorsTitle => '贡献者';

  @override
  String get aboutContactLabel => '联系开发者';

  @override
  String get aboutCoreSourceLabel => '核心源代码';

  @override
  String get aboutDocumentationTitle => '帮助';

  @override
  String get aboutDocumentationSubtitle => '设置、功能与故障排查。';

  @override
  String get documentationPageTitle => '帮助';

  @override
  String get documentationPageSubtitle => 'Etonify 设置与使用的简明说明。';

  @override
  String get documentationGroupGettingStarted => '快速入门';

  @override
  String get documentationGroupConnection => '连接';

  @override
  String get documentationGroupRouting => '路由与 DNS';

  @override
  String get documentationGroupMaintenance => '维护';

  @override
  String get documentationGroupHelp => '诊断';

  @override
  String get documentationGroupDocuments => '文档';

  @override
  String get documentationQuickStartTitle => '快速上手';

  @override
  String get documentationQuickStartBody =>
      '1. 添加订阅或单个服务器。\n2. 运行服务器检测。\n3. 选择服务器或 Lowest。\n4. 点击连接并允许创建 VPN 连接。\n5. 若无法连接，请换一台服务器并打开日志查看。';

  @override
  String get documentationWhatTitle => '关于 Etonify';

  @override
  String get documentationWhatBody =>
      'Etonify 支持 Android 8.0 及更高版本。它是 sing-box 客户端，不是 VPN 服务。请添加服务商提供的订阅或服务器。设置、订阅和日志都保存在本机。';

  @override
  String get documentationModesTitle => 'VPN 与本地代理';

  @override
  String get documentationModesBody =>
      'VPN TUN 通过 Android 系统 VPN 转发应用流量。\n\n本地 HTTP/SOCKS 代理仅在手动配置了其地址的应用中生效。VPN 和本地代理可以同时运行。如需局域网内其他设备使用，请启用局域网访问。';

  @override
  String get documentationProtocolsTitle => '格式与协议';

  @override
  String get documentationProtocolsBody =>
      '支持导入链接、二维码以及 sing-box 或 Xray 配置。\\n\\n支持的协议包括 VLESS、VMess、Trojan、Shadowsocks、ShadowsocksR、Hysteria、Hysteria2、TUIC、AnyTLS、Naive、HTTP 和 SOCKS。导入仅确认格式正确，不保证服务器可用。';

  @override
  String get documentationChainsTitle => '代理链';

  @override
  String get documentationChainsBody =>
      '代理链将流量经由首个代理和出口代理转发，两台服务器都必须可用。延迟通常更高。代理链不提供自动故障转移。';

  @override
  String get documentationSubscriptionsTitle => '订阅与配置';

  @override
  String get documentationSubscriptionsBody =>
      '配置文件保存订阅来源、服务器和上次的选择。可从剪贴板、文件、二维码导入数据，也可以手动添加。自动刷新会按计划更新订阅。若更新失败，之前的数据仍可使用。';

  @override
  String get documentationChecksTitle => '服务器检测';

  @override
  String get documentationChecksBody =>
      'URLTest 通过服务器发送 HTTP 请求，不是 ICMP ping。结果取决于服务器、TLS、测试网站和网络。\n\n短横线表示暂无结果，或网络变化后结果已清除。红色警告图标表示检测失败。最低延迟模式会选择延迟最低的可用服务器。';

  @override
  String get documentationBackgroundTitle => '后台运行与通知';

  @override
  String get documentationBackgroundBody =>
      'VPN 运行时，安卓会显示一条包含服务器、延迟、流量和停止操作的通知。\n\n关闭界面不会停止 VPN。强制停止应用会禁用服务，直到再次打开 Etonify。部分设备需要授予后台活动和自启动权限。';

  @override
  String get documentationRoutingTitle => '分应用隧道与 TUN 协议栈';

  @override
  String get documentationRoutingBody =>
      '分流在 VPN TUN 模式下工作。「走 VPN」将所选应用送入隧道，「VPN 之外」使其保持直连。\n\nsing-tun 使用核心自带的网络协议栈，速度更高、资源占用更低。System 使用 Android 网络协议栈。除非设备出现兼容性问题，否则请保持使用 sing-tun。';

  @override
  String get documentationTrafficRulesTitle => '流量规则';

  @override
  String get documentationTrafficRulesBody =>
      '预设为域名和 IP 地址选择直连或代理路由。一次只能启用一个预设。\n\n分应用代理先选择哪些应用走 VPN，流量规则再为这些连接选择路由。';

  @override
  String get documentationDnsTitle => 'DNS';

  @override
  String get documentationDnsBody =>
      'Etonify 支持设备 DNS、UDP、TCP、DoT 和 DoH。直连使用常规连接，经代理使用所选服务器。\n\nFakeIP 为实验性选项，可能不兼容部分应用。';

  @override
  String get documentationRuleFilesTitle => 'Geo 资源文件';

  @override
  String get documentationRuleFilesBody =>
      '流量预设使用本地 .srs 文件，可离线工作。新版本仅在下载成功后才会替换旧版本。\n\n广告拦截使用单独的 AdGuard 过滤器。请在路由设置中更新文件和过滤器。';

  @override
  String get documentationSecurityTitle => 'TLS 安全';

  @override
  String get documentationSecurityBody =>
      '默认情况下，Etonify 会验证服务器与 HTTPS 订阅的 TLS 证书。可以分别为服务器和订阅关闭验证。仅对可信来源这样做，否则密钥和流量可能被截获。';

  @override
  String get documentationUpdatesTitle => '下载与更新';

  @override
  String get documentationUpdatesBody =>
      '订阅、地理资源、广告拦截过滤器和客户端更新会优先通过已连接的 VPN 下载。失败时，Etonify 会尝试使用 Wi-Fi 或移动数据。如果有其他 VPN 处于活动状态，则应用其规则。\n\n下载有时间和大小限制。APK 文件在安装前会经过校验。';

  @override
  String get documentationBackupTitle => '导入、导出与备份';

  @override
  String get documentationBackupBody =>
      '设置导出不包含订阅或密钥。订阅导出包含配置和服务器。\n\n请用密码保护备份。未加密文件会以明文保存密钥。忘记密码将无法找回。';

  @override
  String get documentationExperimentalTitle => '实验性选项';

  @override
  String get documentationExperimentalBody =>
      'FakeIP、TLS 分片、TCP Fast Open、TCP MultiPath 和多路复用会改变网络行为，正常连接不需要它们。\n\n请一次只修改一个选项，如果连接变差请恢复默认值。';

  @override
  String get documentationDiagnosticsTitle => '日志与资源';

  @override
  String get documentationDiagnosticsBody =>
      '「资源与诊断」显示 VPN 状态、版本和进程内存。PSS、RSS、Private Dirty、Swap、heap、code 和 graphics 不能相加。\n\n出错后请立即导出日志，分享前请检查文件中是否包含隐私数据。';

  @override
  String get documentationLimitsTitle => '重要限制';

  @override
  String get documentationLimitsBody =>
      'Etonify 仅支持 Android，不内置 VPN 服务器。可用性取决于服务器、订阅、DNS、运营商和设备。\n\nURLTest 只检测一个地址，不能保证访问所有网站。大型订阅和全量服务器检测会暂时增加内存、CPU、电池和流量的消耗。';

  @override
  String get telegramChannelLabel => 'Telegram 频道';

  @override
  String get legalTermsTitle => '使用条款';

  @override
  String get legalPrivacyTitle => '隐私政策';

  @override
  String get legalTermsSummary => '合理使用的规则与项目免责声明。';

  @override
  String get legalPrivacySummary => 'Etonify 在本地存储什么，以及不收集什么。';

  @override
  String get legalGateTitle => '使用 Etonify 之前';

  @override
  String legalGateSubtitle(String version) {
    return '自版本 $version 起，请阅读并接受服务条款与隐私政策以继续使用。';
  }

  @override
  String get legalAcceptAction => '接受并继续';

  @override
  String get legalAcceptHint => '请打开两份文档以继续。';

  @override
  String get legalDocumentReadAction => '我已阅读';

  @override
  String get legalContactAction => '提问';

  @override
  String get legalImportBlockedMessage => '请先接受使用条款与隐私政策，再导入订阅。';

  @override
  String get legalTermsBody =>
      '# Etonify 使用条款\n\n## 应用功能\n\nEtonify 是一款安卓 VPN 客户端。**它不出售也不提供 VPN 服务器：**用户自行添加第三方服务商的订阅、配置和服务器。\n\n## 用户责任\n\n请根据适用法律和服务规则使用 Etonify。请勿将其用于攻击、欺诈、恶意软件、骚扰或其他非法活动。\n\n- 您对自己添加的配置和访问密钥负责。\n- 第三方服务商自行决定其服务条款。\n- MeowTeam 不控制订阅内容或第三方服务器的流量。\n\n## 运行与更新\n\nEtonify 按 **现状** 提供。我们会持续提升可靠性和安全性，但无法保证每台服务器、每条路由、每个 DNS 解析器、每家运营商或修改过的安卓固件都能正常工作。更新仅在用户操作并经安卓系统确认后安装。\n\n## 反馈\n\n问题、错误报告和功能建议可以直接发送给开发者：**https://t.me/etonify?direct**。\n\n继续使用即表示您已阅读本条款，并愿意为使用本应用承担责任。';

  @override
  String get legalPrivacyBody =>
      '# Etonify 隐私政策\n\n## 摘要\n\nEtonify **无广告、无分析 SDK、无隐藏追踪**。MeowTeam 不出售用户数据，也不会自动获取您的 VPN 密钥。\n\n## 存储在设备上的数据\n\n订阅、配置、所选服务器、设置、诊断日志和已下载的规则文件均存储在本地。备份和导出可能包含访问密钥，请妥善保管。\n\n## 网络请求\n\n- 导入和刷新订阅时会访问您提供的地址，该服务器可以看到常规请求信息，包括 IP 地址。\n- 客户端与路由规则更新检查会访问 GitHub 及界面中注明的来源。\n- HWID 仅在您启用的配置中发送给订阅服务。\n\n## Android 权限\n\n- **VPN service** 用于创建系统 VPN 隧道。\n- **QUERY_ALL_PACKAGES** 仅用于在分应用代理中显示已安装应用，应用列表不会发送给 MeowTeam。\n- **相机**仅用于扫描二维码。\n- **通知**用于显示 VPN 服务状态。\n- **APK 安装**仅用于安装您确认的更新，Android 会另行显示系统确认。\n\n## 日志与消息\n\n日志保存在本地，直到您自行导出或发送。公开发送前请检查导出文件的内容。通过 Telegram 自愿发送的信息遵循 Telegram 的规则。\n\n隐私问题可直接发送给开发者：**https://t.me/etonify?direct**。';

  @override
  String get coreVersionLabel => '核心版本';

  @override
  String get debugMenuTitle => '调试';

  @override
  String get debugMenuSubtitle => '调试与服务操作的隐藏区域。';

  @override
  String get debugNetworkHeartbeatTitle => '网络心跳';

  @override
  String debugNetworkHeartbeatSubtitle(int seconds) {
    return '若 Android 遗漏回调，则重新确认默认网络。当前间隔：$seconds 秒。下次启动 VPN 时生效。';
  }

  @override
  String get debugWakeLockTitle => '部分唤醒锁';

  @override
  String get debugWakeLockSubtitle =>
      '在 VPN 运行时保持 CPU 唤醒。默认关闭，因为在激进的固件上可能导致手机发热。';

  @override
  String get debugRecordSnapshot => '记录性能快照';

  @override
  String get debugSnapshotDone => '性能快照已添加到日志';

  @override
  String get debugRuntimeMeasurementTitle => '后台运行测量';

  @override
  String get debugRuntimeMeasurementSubtitle =>
      '每 5 秒测量 CPU、内存、核心任务、连接和路由流量。仅在启动后运行，不改变 VPN 路由。';

  @override
  String debugRuntimeMeasurementDuration(String duration) {
    return '时长：$duration';
  }

  @override
  String debugRuntimeMeasurementProgress(String elapsed, String duration) {
    return '运行中：$elapsed / $duration';
  }

  @override
  String get debugRuntimeMeasurementStart => '开始测量';

  @override
  String get debugRuntimeMeasurementStop => '停止测量';

  @override
  String get debugRuntimeMeasurementSave => '保存报告';

  @override
  String get debugRuntimeMeasurementIdle => '就绪，可开始测量';

  @override
  String get debugRuntimeMeasurementCompleted => '测量完成';

  @override
  String get debugRuntimeMeasurementStopped => '测量已停止';

  @override
  String get debugRuntimeMeasurementCollecting => '正在收集数据…';

  @override
  String get debugRuntimeMeasurementHealthy => '未检测到异常的资源增长。';

  @override
  String get debugRuntimeMeasurementHighCpu =>
      '路由流量较低但 CPU 占用高，可能是原生层或核心的后台工作，而非正常的传输负载。';

  @override
  String get debugRuntimeMeasurementGoroutineGrowth => '测量期间核心任务数增加。';

  @override
  String get debugRuntimeMeasurementMemoryGrowth => '测量期间进程内存显著增长。';

  @override
  String get debugRuntimeMeasurementConnectionChurn => '流量较低时，核心存在大量连接。';

  @override
  String get debugRuntimeMeasurementUnavailable => '暂无足够数据进行评估。';

  @override
  String get debugRuntimeMeasurementSaved => '测量报告已就绪，可以保存';

  @override
  String get teamDeveloperDdosxdRole => '核心、网络与自定义协议';

  @override
  String get teamDeveloperYamixdevRole => 'Android 客户端、界面、核心与发布';

  @override
  String get teamDeveloperVerificationInfo => 'Etonify 贡献者。';

  @override
  String get languageSettingTitle => '语言';

  @override
  String get themeSettingTitle => '主题';

  @override
  String get accentColorTitle => '主题色';

  @override
  String get appearanceTitle => '外观';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => '俄语';

  @override
  String get languageChinese => '中文';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get diagnosticsTitle => '资源与诊断';

  @override
  String get diagnosticsSubtitle => '内存、核心状态与诊断。';

  @override
  String get aboutResourcesTitle => '资源';

  @override
  String get aboutResourcesSubtitle => '按需获取 Android 与核心快照。CPU 按一秒测量。';

  @override
  String get aboutResourcesPssTitle => '进程内存';

  @override
  String get aboutResourcesPssSubtitle =>
      'PSS 是包含共享页面分摊的主要内存估算。RSS 统计所有常驻页面，Private Dirty 统计仅归属本进程的已修改页面，Swap PSS 是其按比例分摊的交换分区份额。请勿将这些数值相加。';

  @override
  String get aboutResourcePss => '总 PSS';

  @override
  String get aboutResourceRss => '总 RSS';

  @override
  String get aboutResourceSwapPss => 'Swap PSS';

  @override
  String get aboutResourcePrivateDirty => '私有脏页';

  @override
  String get aboutResourceNativePss => '原生 PSS';

  @override
  String get aboutResourceDalvikPss => 'Android VM PSS';

  @override
  String get aboutResourceOtherPss => '其他 PSS';

  @override
  String get aboutResourceGraphicsPss => '图形 PSS';

  @override
  String get aboutResourceCodePss => '代码 PSS';

  @override
  String get aboutResourceStackPss => '栈 PSS';

  @override
  String get aboutResourcesRuntimeTitle => '客户端与核心';

  @override
  String get aboutResourceNativeHeap => '原生堆';

  @override
  String get aboutResourceJavaHeap => 'Java 堆';

  @override
  String get aboutResourceCoreMemory => '核心上报的进程 RSS';

  @override
  String get aboutResourceFlutterImageCache => 'Flutter 图片缓存';

  @override
  String get aboutResourceCoreGoroutines => '核心协程';

  @override
  String get aboutResourceCoreConnections => '核心连接（入站 / 出站）';

  @override
  String get aboutResourcesSystemTitle => '系统';

  @override
  String get aboutResourceProcessCpu => '进程 CPU，全部核心';

  @override
  String get aboutResourceSystemMemory => '系统空闲 RAM';

  @override
  String get aboutResourceBatteryTemp => '电池温度';

  @override
  String get updatesTitle => '更新';

  @override
  String get updatesSubtitle => '检查新版本并安装。';

  @override
  String get updatesChecking => '正在检查更新…';

  @override
  String get updatesCheckAction => '立即检查';

  @override
  String get updatesChannelMenuAction => '更新渠道';

  @override
  String get updatesChannelTitle => '更新渠道';

  @override
  String get updatesChannelStable => '稳定版';

  @override
  String get updatesChannelStableSubtitle => '适合日常使用的稳定版本。';

  @override
  String get updatesChannelBeta => 'Beta';

  @override
  String get updatesChannelBetaSubtitle =>
      '测试以 GitHub 预发布形式发布的 alpha、beta 和 RC 版本。';

  @override
  String get updatesChannelBetaWarning => '测试版可能包含错误。当稳定版新于已安装版本时，可返回稳定通道。';

  @override
  String get updatesPrereleaseVersionTooltip => '测试版';

  @override
  String get updatesRetryAction => '重试';

  @override
  String get updatesUnsupportedAndroidTitle => '不支持更新';

  @override
  String updatesUnsupportedAndroidSubtitle(String version, int minSdk) {
    return '版本 $version 需要 Android SDK $minSdk 或更高。此设备可继续使用最新兼容版本。';
  }

  @override
  String get updatesDownloadAction => '下载更新';

  @override
  String get updatesInstallAction => '安装 APK';

  @override
  String get updatesDownloadWarning => '请保持 Etonify 打开，直到下载完成。';

  @override
  String get updatesOpeningInstaller => '正在打开系统安装器…';

  @override
  String get updatesInstallPermissionHint =>
      '请允许为 Etonify 安装 APK，然后再次点击“安装 APK”。';

  @override
  String get updatesInstallPermissionTitle => '需要权限';

  @override
  String get updatesInstallPermissionMessage =>
      '请先允许 Etonify 安装未知应用，它才能打开已下载的 APK 安装包。没有此权限，你只能手动下载文件。';

  @override
  String get updatesInstallPermissionOpen => '打开设置';

  @override
  String get updatesInstallPermissionGranted => '已启用 APK 安装权限。';

  @override
  String get updatesInstallModeTitle => '更新安装';

  @override
  String get updatesInstallModeAsk => '每次都询问';

  @override
  String get updatesInstallModeAskSubtitle => '下载前 Etonify 会询问手动下载还是自动安装。';

  @override
  String get updatesInstallModeManual => '手动';

  @override
  String get updatesInstallModeManualSubtitle => '客户端下载 APK 后会显示安装按钮。';

  @override
  String get updatesInstallModeAuto => '自动';

  @override
  String get updatesInstallModeAutoSubtitle => '客户端下载 APK 后打开安卓安装器。';

  @override
  String get updatesInstallMethodTitle => '如何安装此更新？';

  @override
  String get updatesInstallMethodManualTitle => '手动下载';

  @override
  String get updatesInstallMethodManualSubtitle => 'APK 已保存到更新缓存中，稍后可以手动安装。';

  @override
  String get updatesInstallMethodAutoTitle => '下载并安装';

  @override
  String get updatesInstallMethodAutoSubtitle =>
      '下载完成后，Etonify 将打开 Android 系统安装器。';

  @override
  String get updatesInstallMethodRemember => '记住此选择';

  @override
  String get updatesApkVerificationTitle => 'APK 校验';

  @override
  String get updatesApkVerificationVerified => 'SHA-256 一致';

  @override
  String get updatesApkVerificationUnavailable => '此版本未提供 SHA-256';

  @override
  String get updatesApkVerificationFailed => 'SHA-256 不匹配';

  @override
  String get updatesDownloadedFileMissing => '更新文件丢失，请重新下载 APK。';

  @override
  String get updatesDeleteCachedApkAction => '删除安装包 APK';

  @override
  String get updatesDeleteCachedApkTitle => '删除安装包 APK？';

  @override
  String updatesDeleteCachedApkMessage(Object version) {
    return '这将删除应用缓存中已下载的 $version 更新 APK 以及旧的临时 Etonify APK 文件。';
  }

  @override
  String updatesDeleteCachedApkDone(int count) {
    return '更新缓存已清理。已删除文件：$count。';
  }

  @override
  String get updatesUpToDateTitle => 'Etonify 已是最新版本';

  @override
  String updatesUpToDateSubtitle(String version) {
    return '已安装版本：$version';
  }

  @override
  String get updatesCurrentVersionNewerTitle => '已安装版本更新';

  @override
  String updatesCurrentVersionNewerSubtitle(
    String currentVersion,
    String channelVersion,
  ) {
    return '已安装：$currentVersion。所选通道：$channelVersion。无需更新。';
  }

  @override
  String get updatesNoChannelReleaseTitle => '此通道暂无版本';

  @override
  String get updatesNoBetaReleaseSubtitle => 'GitHub 上尚未发布 Etonify 预发布版本。';

  @override
  String get updatesNoStableReleaseSubtitle => 'GitHub 上尚未发布 Etonify 正式版。';

  @override
  String get updatesAvailableTitle => '有可用更新';

  @override
  String updatesAvailableSubtitle(String version, String size) {
    return '$version · $size';
  }

  @override
  String get updatesAvailableSnack => '有可用的客户端更新';

  @override
  String updatesAvailableSnackVersion(Object version) {
    return '客户端更新 $version 可用';
  }

  @override
  String get updatesOpenAction => '打开';

  @override
  String get updatesDownloadingTitle => '正在下载更新';

  @override
  String get updatesStageCleaning => '正在删除旧文件…';

  @override
  String get updatesStageVerifying => '正在验证 APK 与签名…';

  @override
  String get updatesDownloadedTitle => '更新已下载';

  @override
  String updatesDownloadedSubtitle(String fileName) {
    return '已保存到应用更新缓存：$fileName';
  }

  @override
  String get updatesErrorTitle => '无法检查更新';

  @override
  String get updatesErrorSubtitle => '如果此网络屏蔽了 GitHub，Etonify 将在明天重试。';

  @override
  String get updatesCurrentVersion => '当前版本';

  @override
  String get updatesLatestVersion => '最新版本';

  @override
  String get updatesAsset => 'APK';

  @override
  String updatesLastChecked(String time) {
    return '上次检查：$time';
  }

  @override
  String get updatesReleaseNotesTitle => '更新内容';

  @override
  String get updatesNoReleaseNotes => '此版本没有更新说明。';

  @override
  String updatesProgressBytes(String downloaded, String total) {
    return '$downloaded / $total';
  }

  @override
  String updatesProgressSpeedEta(String speed, String eta) {
    return '$speed/秒 · 还剩 $eta';
  }

  @override
  String updatesEtaSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String updatesEtaMinutes(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String get updatesUnknownSize => '大小未知';

  @override
  String get appVersionLabel => '应用版本';

  @override
  String get currentProfileLabel => '当前配置';

  @override
  String get selectedProxyLabel => '所选代理';

  @override
  String get onboardingStatusLabel => '引导';

  @override
  String get onboardingSeen => '已完成';

  @override
  String get showOnboardingAgain => '再次显示引导页';

  @override
  String get settingsFootnote => '这些设置仅保存在本设备（Hive 数据库）中。';

  @override
  String get connected => '已连接';

  @override
  String get tapToConnect => '点击连接';

  @override
  String get resolvingIp => '正在解析 IP…';

  @override
  String get millisecondsUnit => ' 毫秒';

  @override
  String get refreshLatency => '刷新延迟';

  @override
  String get checkingLatency => '正在检测延迟';

  @override
  String get checkingLatencyShort => '检测中……';

  @override
  String get openTrafficDashboard => '打开流量看板';

  @override
  String get refreshActiveSubscription => '刷新当前订阅';

  @override
  String get refreshActiveSubscriptionUnavailable => '手动导入的订阅无法刷新';

  @override
  String activeSubscriptionRefreshComplete(String name) {
    return '$name 已更新';
  }

  @override
  String get trafficDashboardTitle => '流量监控';

  @override
  String get trafficDashboardSubtitle => '实时速度、会话流量与连接信息';

  @override
  String get trafficDashboardDownload => '下载';

  @override
  String get trafficDashboardUpload => '上传';

  @override
  String get trafficDashboardSessionTraffic => '会话流量';

  @override
  String get trafficDashboardConnectedFor => '已连接时长';

  @override
  String get trafficDashboardGraphTitle => '网速';

  @override
  String trafficDashboardGraphMax(String speed) {
    return '峰值 $speed';
  }

  @override
  String get trafficDashboardNoSamples => '等待流量数据';

  @override
  String get trafficDashboardConnectionState => '连接';

  @override
  String get trafficDashboardCurrentProfile => '配置';

  @override
  String get trafficDashboardActiveProxy => '代理';

  @override
  String get trafficDashboardServerIp => '服务器 IP';

  @override
  String get trafficDashboardPublicIp => '你的 IP';

  @override
  String get trafficDashboardPublicIpHint => '当前连接的公网地址';

  @override
  String get trafficDashboardPublicIpRefresh => '刷新你的 IP';

  @override
  String get trafficDashboardPublicIpError => '无法刷新您的 IP，请重试。';

  @override
  String get trafficDashboardPublicIpCooldown => '每 4 秒可刷新一次';

  @override
  String get homeOutboundIpTitle => '出站 IP';

  @override
  String get homeOutboundIpHint => '通过第三方网站查询 IP，仅供参考';

  @override
  String get homeOutboundIpExpand => '查看出站 IP 详情';

  @override
  String get homeOutboundIpCollapse => '收起出站 IP 详情';

  @override
  String get homeOutboundIpLoading => '正在查询出站 IP…';

  @override
  String get homeOutboundIpUnavailable => '暂无出站 IP';

  @override
  String get homeOutboundIpBasicSection => '基础信息';

  @override
  String get homeOutboundIpAddress => 'IP 地址';

  @override
  String get homeOutboundIpCountry => '国家 / 地区';

  @override
  String get homeOutboundIpNetworkSection => '网络';

  @override
  String get homeOutboundIpOrganization => '组织';

  @override
  String get homeOutboundIpAsn => 'ASN';

  @override
  String get homeOutboundIpIsp => '网络运营商';

  @override
  String get homeOutboundIpSource => '采用来源';

  @override
  String get homeOutboundIpSourceIpQuery => 'ipquery.io';

  @override
  String get homeOutboundIpSourceIpApi => 'ip-api.com';

  @override
  String get homeOutboundIpSourceIpWho => 'ipwho.is';

  @override
  String get ipLookupSourceTitle => 'IP 检测源';

  @override
  String get ipLookupSourceDescription => '选择用于查询公网 IP 位置的网站';

  @override
  String get ipLookupSourceDialogTitle => '选择查询网站';

  @override
  String get ipLookupSourceIpQuerySubtitle => 'HTTPS · 无需 API 密钥';

  @override
  String get ipLookupSourceIpApiSubtitle => '仅 HTTP · 非商业用途 · 每分钟最多 45 次';

  @override
  String get ipLookupSourceIpWhoSubtitle => '免费版每天最多 1,000 次';

  @override
  String get trafficDashboardDownloadTotal => '已下载';

  @override
  String get trafficDashboardUploadTotal => '已上传';

  @override
  String get trafficDashboardStateConnected => '已连接';

  @override
  String get trafficDashboardStateConnecting => '连接中';

  @override
  String get trafficDashboardStateDisconnected => '已断开';

  @override
  String trafficDashboardUptimeHours(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String trafficDashboardUptimeMinutes(int minutes, int seconds) {
    return '$minutes 分 $seconds 秒';
  }

  @override
  String trafficDashboardUptimeSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get notAvailableShort => '无';

  @override
  String daysLeft(int days) {
    return '剩余 $days 天';
  }

  @override
  String get daysLeftUnlimited => '剩余 ∞ 天';

  @override
  String get unlimitedTraffic => '无限';

  @override
  String get unlimitedSymbol => '∞';

  @override
  String get welcomeGreeting => '你好';

  @override
  String get welcomeTitlePrefix => '欢迎使用';

  @override
  String get welcomeSubtitle => '快速的 Android VPN 客户端';

  @override
  String get welcomeTapHint => '点击任意位置继续';

  @override
  String get hapticTitle => '振动';

  @override
  String get hapticSubtitle => '重要操作时轻微振动';

  @override
  String get statusNotificationTitle => '通知状态';

  @override
  String get statusNotificationSubtitle => 'VPN 激活期间显示所选服务器、速度与延迟。';

  @override
  String get notificationSettingsTitle => 'VPN 通知';

  @override
  String get notificationSettingsSubtitle => '服务器、流量、延迟与刷新频率。';

  @override
  String get notificationTrafficDisplayTitle => '通知显示内容';

  @override
  String get notificationTrafficDisplaySubtitle => '当前速度、总传输量，或两者。';

  @override
  String get notificationTrafficDisplaySpeed => '当前速度';

  @override
  String get notificationTrafficDisplayTotal => '累计传输';

  @override
  String get notificationTrafficDisplayBoth => '速度与总量';

  @override
  String get notificationTrafficTotalLabel => '总流量';

  @override
  String get notificationTrafficRefreshTitle => '流量刷新';

  @override
  String get notificationTrafficRefreshSubtitle => '通知中数据的更新频率。';

  @override
  String notificationTrafficRefreshSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get notificationConnected => 'VPN 已连接';

  @override
  String get notificationPingChecking => '...';

  @override
  String get notificationPingUnavailable => '延迟不可用';

  @override
  String get notificationRefreshPingAction => '刷新延迟';

  @override
  String get notificationStopAction => '停止';

  @override
  String get hideServerIpTitle => '隐藏服务器 IP';

  @override
  String get hideServerIpSubtitle => '隐藏 IP 地址的最后两个字节段';

  @override
  String get memoryLimitTitle => '核心内存软限制';

  @override
  String get memoryLimitEnabledSubtitle =>
      '对 sing-box Go 部分管理内存的可选自适应上限。数值立即生效，不限制整个应用。';

  @override
  String get memoryLimitDisabledSubtitle =>
      '已禁用。sing-box 的 Go 部分将在无 Etonify 内存预算的情况下管理内存，可能会占用更多内存。重启应用后生效。';

  @override
  String get memoryLimitDisableWarningTitle => '关闭核心软限制？';

  @override
  String get memoryLimitDisableWarningMessage =>
      '关闭软限制后，sing-box 的 Go 部分可能更久地保留未使用的内存。这不会改变 Flutter 或 Android 的内存限制，也不会影响系统对进程的回收。更改将在重启 Etonify 后生效。';

  @override
  String get memoryLimitDisableConfirm => '禁用';

  @override
  String get enableInboundTitle => '已启用';

  @override
  String get vpnInDescription =>
      'VPN TUN 是安卓系统 VPN 通道，用于手机流量。应用看到的是一个安卓 VPN，路由规则决定哪些流量走代理、哪些直连。';

  @override
  String get vpnInboundEnabledSubtitle => '创建 VPN TUN 入站并经其转发流量';

  @override
  String get inboundNoneEnabled => '启动前请先启用 VPN TUN 或代理入站。';

  @override
  String get mtuTitle => 'MTU';

  @override
  String get mtuSubtitle => 'TUN 接口数据包大小';

  @override
  String get mtuInputRange => '请输入 1280 到 9000 之间的数值。';

  @override
  String get mtuInvalidValue => '请输入 1280 到 9000 之间的值。';

  @override
  String get strictRouteTitle => '防止 VPN 被绕过';

  @override
  String get strictRouteSubtitle => '强制流量经过 VPN，降低流量绕过隧道泄漏的风险';

  @override
  String get tunImplementationTitle => 'TUN 网络栈';

  @override
  String get tunImplementationSubtitle => '控制客户端在 VPN 内处理 TCP 与 UDP 流量的方式';

  @override
  String get tunImplementationNative => 'sing-tun（推荐）';

  @override
  String get tunImplementationNativeSubtitle => '处理 VPN 流量的内置网络协议栈。';

  @override
  String get tunImplementationSystem => '系统（Android）';

  @override
  String get tunImplementationSystemSubtitle =>
      'TCP 与 UDP 走 Android 系统网络栈，兼容性取决于设备与固件。';

  @override
  String get vpnEnableIpv6Title => 'IPv6 支持';

  @override
  String get vpnEnableIpv6Subtitle => '经由 TUN 路由 IPv6。如果您的运营商或代理不支持 IPv6，请关闭。';

  @override
  String get proxyInDescription =>
      '代理入口/混合模式是供手动配置的应用或其他设备使用的本地 HTTP/SOCKS 入口，不是 Android 系统 VPN。';

  @override
  String get proxyInboundEnabledSubtitle => '为应用和设备启动本地混合入站';

  @override
  String get allowLanConnectionsTitle => '允许局域网连接';

  @override
  String get allowLanConnectionsSubtitle => '启用后监听 0.0.0.0，否则仅监听 127.0.0.1';

  @override
  String get portTitle => '端口';

  @override
  String get proxyPortSubtitle => '本地混合入站端口';

  @override
  String get connectionModeTitle => '连接模式';

  @override
  String get connectionModeSubtitle => 'VPN 覆盖整部手机。本地代理仅供手动配置了其地址的应用和设备使用。';

  @override
  String get connectionModeVpn => 'VPN';

  @override
  String get connectionModeVpnSubtitle => '面向手机全部流量的系统级 Android VPN';

  @override
  String get connectionModeProxy => '代理';

  @override
  String get connectionModeProxySubtitle => '不使用系统 VPN 的本地 HTTP/SOCKS';

  @override
  String connectionModeActiveStatus(String mode) {
    return '已激活：$mode';
  }

  @override
  String get connectionModeVpnStatusName => 'VPN TUN';

  @override
  String get connectionModeProxyStatusName => '代理';

  @override
  String get advancedTunTitle => '高级 TUN 设置';

  @override
  String get advancedTunSubtitle => 'MTU、严格路由与网络栈实现';

  @override
  String get localProxyTitle => '本地代理';

  @override
  String get localProxySubtitle => '供手动配置的应用使用的额外 HTTP/SOCKS 入口';

  @override
  String get localProxySettingsSubtitle => '地址、端口和访问凭据';

  @override
  String get lanProxySecurityTitle => '访问受保护';

  @override
  String get lanProxySecuritySubtitle =>
      '局域网设备需要提供用户名和密码。身份验证可防止未授权使用，但本身不会加密本地网络。';

  @override
  String get proxyUsernameTitle => '用户名';

  @override
  String get proxyUsernameSubtitle => '1–64 个字符，不含空格或冒号';

  @override
  String get proxyPasswordTitle => '密码';

  @override
  String get regenerateProxyPasswordTitle => '修改密码';

  @override
  String get copyProxyCredentialsTitle => '复制连接信息';

  @override
  String get proxyCredentialsCopied => '代理连接信息已复制';

  @override
  String get proxyEndpointTitle => '地址';

  @override
  String get proxyLanAddressHint => '手机 IP';

  @override
  String get dnsUsePresetTitle => '使用预设';

  @override
  String get dnsResolverTitle => '解析器';

  @override
  String get dnsDirectPresetSubtitle => '推荐：udp://1.1.1.1';

  @override
  String get dnsDirectResolverSubtitle => '不走代理的直连请求所用 DNS';

  @override
  String get dnsProxyPresetSubtitle =>
      '推荐：https://dns.cloudflare.com/dns-query';

  @override
  String get dnsProxyResolverSubtitle => '经代理发出的请求的 DNS';

  @override
  String get dnsResolverTypeTitle => '解析器类型';

  @override
  String get dnsPresetDevice => '设备网络';

  @override
  String get dnsPresetCustom => '自定义';

  @override
  String get dnsPresetDeviceSubtitle => '使用当前安卓网络的 DNS。';

  @override
  String get dnsPresetCustomSubtitle =>
      '输入 IP/主机名（默认 UDP），或使用 udp://、tcp://、tls://、https://。';

  @override
  String get dnsPresetUdpSubtitle => '普通 UDP DNS。速度快，但不加密。';

  @override
  String get dnsPresetTcpSubtitle => '普通 TCP DNS。部分网络下更稳定，但未加密。';

  @override
  String get dnsPresetTlsSubtitle => 'DNS over TLS。853 端口上的加密 DNS。';

  @override
  String get dnsPresetHttpsSubtitle =>
      'DNS over HTTPS。经 HTTPS 加密的 DNS，通常经代理效果最佳。';

  @override
  String get dnsProtectionTitle => '防护';

  @override
  String get dnsSecureOnlyTitle => '仅加密 DNS';

  @override
  String get dnsSecureOnlySubtitle => '仅允许 DoH 和 DoT。不使用明文 UDP、TCP 和设备 DNS。';

  @override
  String get dnsDirectThroughProxyTitle => '直连 DNS（经代理）';

  @override
  String get dnsDirectThroughProxySubtitle => '为直连路由的 DNS 提供保护，同时网站流量保持直连。';

  @override
  String get urlTestUrlTitle => '测试地址';

  @override
  String get urlTestUrlSubtitle => '若订阅已定义该值，则使用订阅的值';

  @override
  String get urlTestIntervalTitle => '间隔，秒。';

  @override
  String get urlTestIntervalCompactTitle => '检查间隔';

  @override
  String get urlTestIntervalSubtitle => '自动选择时代理的检测频率';

  @override
  String get urlTestTimeoutTitle => '超时（秒）';

  @override
  String get urlTestTimeoutCompactTitle => '测试超时';

  @override
  String get urlTestTimeoutSubtitle => '单个代理测试超时前等待的时长';

  @override
  String get urlTestConcurrencyTitle => '测试并发数';

  @override
  String get urlTestConcurrencySubtitle => 'URLTest 同时检测的代理数量';

  @override
  String get urlTestSingleRetestTitle => '快速重试延迟，秒。';

  @override
  String get urlTestSingleRetestCompactTitle => '快速重试';

  @override
  String get urlTestSingleRetestSubtitle => '代理失败后，多久进行一次快速复测';

  @override
  String get locationLookupTitle => '位置';

  @override
  String get locationLookupSubtitle => '经代理自身查询 IP 与国家/地区';

  @override
  String get locationLookupLimitTitle => '检测最优代理';

  @override
  String get locationLookupLimitSubtitle =>
      'URLTest 之后，应用会为指定数量的最快出站解析外部 IP 和国家/地区';

  @override
  String get locationLookupTimeoutTitle => '请求超时';

  @override
  String get locationLookupTimeoutSubtitle => '单个服务器等待外部 IP 和国家信息的时长';

  @override
  String get locationLookupConcurrencyTitle => '并行请求数';

  @override
  String get locationLookupConcurrencySubtitle => '可同时运行的位置查询数量';

  @override
  String settingsSecondsShort(int seconds) {
    return '$seconds秒';
  }

  @override
  String get serverRequestTitle => '服务器请求';

  @override
  String get sendHwidTitle => '发送 HWID';

  @override
  String get sendHwidSubtitle => '部分订阅服务商需要';

  @override
  String get sendHwidGlobalEnabledSubtitle =>
      '由于已启用全局服务商权限，HWID 会被发送。在此处关闭不会覆盖全局设置。';

  @override
  String get useCustomHwidTitle => '设置自定义 HWID';

  @override
  String get useCustomHwidSubtitle => '使用此 HWID，而非本设备的 HWID';

  @override
  String get customUserAgentTitle => '自定义 User-Agent';

  @override
  String get customUserAgentSubtitle => '覆盖此订阅的默认 Etonify User Agent';

  @override
  String get customHwidTitle => '自定义 HWID';

  @override
  String get customHwidSubtitle => '留空以使用设备 HWID';

  @override
  String get customRequestHeadersTitle => '自定义请求头';

  @override
  String get customRequestHeadersSubtitle => '每行一个请求头，格式为 Header: value';

  @override
  String get hwidTitle => 'HWID';

  @override
  String get hwidSubtitle => '部分订阅服务商使用的设备标识符';

  @override
  String get hwidValueTitle => '你的 HWID';

  @override
  String get coreStartFailedTitle => '核心启动失败';

  @override
  String coreStartFailedMessage(String message) {
    return 'sing-box 启动失败。\n\n$message';
  }

  @override
  String get vpnStopFailed => 'VPN 未完全停止。请打开日志后重试。';

  @override
  String get clearLogsTitle => '清空日志';

  @override
  String get logsFilterTitle => '筛选';

  @override
  String get logsFilterAll => '全部';

  @override
  String get singBoxLogLevelTitle => 'sing-box 日志级别';

  @override
  String get logLevelTrace => 'Trace';

  @override
  String get logLevelDebug => '调试';

  @override
  String get logLevelInfo => '信息';

  @override
  String get logLevelWarning => '警告';

  @override
  String get logLevelError => '错误';

  @override
  String get noLogsTitle => '暂无日志';

  @override
  String get continueLabel => '开始使用';

  @override
  String get subscriptionsTab => '订阅';

  @override
  String get subscriptionsTitle => '订阅';

  @override
  String get settingsProfilesChecksTitle => '订阅与检测';

  @override
  String get settingsProfilesChecksSubtitle => '服务器检测 · HWID · 配置选项';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get addSubscriptionQuickTitle => '添加配置';

  @override
  String get addSubscriptionQuickSubtitle => '选择导入订阅的方式。';

  @override
  String get addSubscriptionFromClipboard => '剪贴板';

  @override
  String get addSubscriptionManual => '手动';

  @override
  String get addSubscriptionReadingClipboard => '正在读取剪贴板…';

  @override
  String get addSubscriptionReadingFile => '正在读取文件…';

  @override
  String get addSubscriptionImporting => '正在导入订阅…';

  @override
  String get addSubscriptionSaving => '正在保存配置…';

  @override
  String get addSubscriptionDone => '订阅已添加';

  @override
  String get clipboardEmpty => '剪贴板为空';

  @override
  String get scanQrCode => '扫描二维码';

  @override
  String get showQrCode => '显示二维码';

  @override
  String get subscriptionQrTitle => '订阅二维码';

  @override
  String get subscriptionQrHint => '在另一台设备上扫描此二维码以导入订阅。';

  @override
  String get subscriptionQrUnsupported => '此订阅暂不支持以二维码分享。';

  @override
  String get invalidQrSubscription => '二维码不包含受支持的订阅链接。';

  @override
  String get subscriptionUrl => '订阅 URL';

  @override
  String get editSubscriptionUrlAction => '编辑 URL';

  @override
  String get saveAction => '保存';

  @override
  String get subscriptionUrlEditHint =>
      '一个配置只能从一个 URL 更新。若旧导入把多个链接合并在了一起，请保留需要的链接，其余来源另建配置添加。保存后请刷新订阅。';

  @override
  String get subscriptionUrlSingleSourceRequired => '只保留一个 URL，其他来源请添加为单独的配置。';

  @override
  String get subscriptionUrlOrContent => 'URL 或内容';

  @override
  String get subscriptionUrlOrContentHint => '粘贴 URL、vless:// 链接、链接列表或配置';

  @override
  String get importFromFile => '从文件导入';

  @override
  String get invalidSubscriptionFile => '读取订阅文件失败';

  @override
  String get backupUseSettingsImport => '这是 Etonify 备份文件。请从「设置 → 导入」导入。';

  @override
  String get subscriptionName => '名称（可选）';

  @override
  String get add => '添加';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get refresh => '刷新';

  @override
  String get reparseProxies => '重新解析代理';

  @override
  String get subscriptionLocalImportBadge => '本地导入';

  @override
  String get refreshAll => '全部刷新';

  @override
  String get refreshSubscriptions => '刷新订阅';

  @override
  String get subscriptionSortTitle => '订阅排序';

  @override
  String get subscriptionSortManual => '当前顺序';

  @override
  String get subscriptionSortByName => '按名称';

  @override
  String get subscriptionSortByUpdated => '按最后更新';

  @override
  String get subscriptionSortByServers => '按代理数量';

  @override
  String get subscriptionActionsTitle => '订阅操作';

  @override
  String get subscriptionCopyUrl => '复制 URL 到剪贴板';

  @override
  String get subscriptionShowUrlQr => '显示 URL 二维码';

  @override
  String get subscriptionUrlCopied => '订阅链接已复制';

  @override
  String get subscriptionImportHelpTitle => '如何添加订阅';

  @override
  String get subscriptionImportHelpBody =>
      '从您的服务商处复制订阅链接并点击「剪贴板」，或扫描二维码。如果链接无法识别，请打开「手动」并粘贴 URL、vless:// 链接、密钥列表或 sing-box/Xray 配置。如果服务商要求，可在手动导入中设置 User-Agent 或 HWID。';

  @override
  String subscriptionsRefreshAllComplete(int updated, int failed) {
    return '已更新 $updated 个订阅，$failed 个失败';
  }

  @override
  String subscriptionsRefreshAllProgress(int completed, int total) {
    return '正在更新 $completed / $total';
  }

  @override
  String get deleteSubscription => '删除订阅？';

  @override
  String get deleteSubscriptionConfirm => '这将删除该订阅中的所有代理。';

  @override
  String get subscriptionDetailsTitle => '订阅';

  @override
  String get subscriptionMovedTitle => '订阅已迁移';

  @override
  String get ignoreAction => '忽略';

  @override
  String get updateUrlAction => '更新 URL';

  @override
  String get autoUpdateTitle => '自动更新';

  @override
  String get disableAutoUpdateTitle => '禁用自动更新';

  @override
  String get disabledLabel => '已禁用';

  @override
  String refreshesEvery(String interval) {
    return '刷新间隔：$interval';
  }

  @override
  String get usageTitle => '用量';

  @override
  String spentTraffic(String usage) {
    return '已用 $usage';
  }

  @override
  String untilDate(String date) {
    return '有效期至 $date';
  }

  @override
  String get infoTitle => '信息';

  @override
  String get supportUrlLabel => '支持';

  @override
  String get websiteLabel => '网站';

  @override
  String get newUrlTitle => '新建 URL';

  @override
  String get movedSubscriptionMessage => '服务器报告该订阅已迁移到新的 URL。';

  @override
  String get movedSubscriptionPrompt => '服务器报告了新的订阅 URL。现在更新还是保留当前 URL？';

  @override
  String get noSubscriptions => '暂无订阅';

  @override
  String get noProxies => '没有代理';

  @override
  String get noSubscriptionsHint => '点击 + 添加订阅 URL';

  @override
  String outboundsCount(int count) {
    return '$count 个代理';
  }

  @override
  String subscriptionServersCount(int count) {
    return '$count 个代理';
  }

  @override
  String get subscriptionReparseRecommended => '需要重新解析';

  @override
  String get subscriptionProxyTypeLabel => '代理';

  @override
  String moreProxies(int count) {
    return '…还有 $count 个代理';
  }

  @override
  String lastUpdatedDateTime(String date, String time) {
    return '更新于 $date $time';
  }

  @override
  String trafficUsage(String used, String total) {
    return '$used / $total';
  }

  @override
  String get expired => '已过期';

  @override
  String get loading => '加载中…';

  @override
  String get error => '错误';

  @override
  String get invalidUrl => '请输入有效的 URL';

  @override
  String get fetchFailed => '获取订阅失败';

  @override
  String get subscriptionSavedWithFetchWarning =>
      '订阅已保存，但服务器无响应。您可以稍后更改 HWID 或请求头再刷新。';

  @override
  String subscriptionSavedWithFetchWarningReason(String reason) {
    return '订阅已保存，但没有服务器。原因：$reason 请检查链接、HWID 或请求头，然后刷新订阅。';
  }

  @override
  String get subscriptionErrorInvalidUrl =>
      '订阅链接无效。请重新复制，并确保以 http:// 或 https:// 开头。';

  @override
  String get subscriptionErrorHttpsRequired =>
      '请使用 HTTPS 地址加载此订阅。明文 HTTP 仅允许本地回环地址。';

  @override
  String get subscriptionErrorUnsafeRedirect =>
      '订阅服务器试图从 HTTPS 重定向到不安全的 HTTP，Etonify 已拦截此次重定向。';

  @override
  String get subscriptionErrorRedirect => '订阅链接重定向不正确或次数过多。请向提供商索取直接链接。';

  @override
  String get subscriptionErrorHttp400 => '服务器拒绝了请求（HTTP 400）。请检查链接及其参数。';

  @override
  String get subscriptionErrorHttp401 => '授权失败（HTTP 401）。令牌、登录名或 HWID 可能无效。';

  @override
  String get subscriptionErrorHttp402 => '需要付款（HTTP 402）。请续订订阅或联系提供商。';

  @override
  String get subscriptionErrorHttp403 =>
      '访问被拒绝（HTTP 403）。订阅可能已过期、被封禁，或需要正确的 HWID。';

  @override
  String get subscriptionErrorHttp404 => '未找到订阅（HTTP 404）。链接可能已被删除或复制有误。';

  @override
  String get subscriptionErrorHttp408 => '订阅服务器超时（HTTP 408），请稍后重试。';

  @override
  String get subscriptionErrorHttp410 => '订阅已过期或被删除（HTTP 410），请向提供方索取新链接。';

  @override
  String get subscriptionErrorHttp429 => '请求过于频繁（HTTP 429）。请稍后再试。';

  @override
  String get subscriptionErrorHttp500 => '订阅服务器发生内部错误（HTTP 500），这是服务商侧的问题。';

  @override
  String get subscriptionErrorHttp502 => '订阅网关不可用（HTTP 502）。服务商当前无法连接到其上游服务器。';

  @override
  String get subscriptionErrorHttp503 => '订阅服务暂时不可用（HTTP 503），可能正在维护。';

  @override
  String get subscriptionErrorHttp504 => '服务商的上游服务器未及时响应（HTTP 504），请稍后再试。';

  @override
  String subscriptionErrorHttpStatus(int status) {
    return '订阅服务器返回了 HTTP $status。请检查服务商状态或索取新链接。';
  }

  @override
  String get subscriptionErrorDns => '找不到订阅主机。请检查域名、DNS 和网络连接。';

  @override
  String get subscriptionErrorConnection => '无法连接到订阅服务器，请检查网络连接或稍后重试。';

  @override
  String get subscriptionErrorTls => '与订阅服务器的安全连接失败。其 TLS 证书可能无效或已过期。';

  @override
  String get subscriptionErrorEmptyResponse => '订阅服务器返回了空响应。链接可能已过期，或服务商出现了问题。';

  @override
  String get subscriptionErrorHtmlResponse =>
      '服务器返回的是网页而非订阅内容。该链接可能打开了登录页或错误页。';

  @override
  String get subscriptionErrorResponseTooLarge => '订阅响应过大，已被拦截以保护应用。';

  @override
  String get subscriptionErrorNoUsableProxies =>
      '订阅中未找到受支持的代理服务器。订阅可能为空、已过期，或使用了不受支持的格式。';

  @override
  String get wireGuardUnsupportedMessage =>
      '自 0.3.1 版本起，Etonify 因协议稳定性问题不再支持 WireGuard。请使用其他协议的服务器。';

  @override
  String get wireGuardServersSkippedMessage =>
      '已跳过 WireGuard 服务器。自 0.3.1 版本起，Etonify 因协议稳定性问题不再支持 WireGuard。';

  @override
  String get subscriptionErrorInvalidContent =>
      '服务器返回的内容不是有效的订阅，请确认链接直接指向订阅文件。';

  @override
  String get subscriptionErrorUnknown => '无法处理该订阅。请检查链接，并打开诊断页面查看技术原因。';

  @override
  String get sourceLabel => '来源';

  @override
  String importedFromFileLabel(String name) {
    return '从文件导入：$name';
  }

  @override
  String get deepLinkImportTitle => '导入订阅';

  @override
  String get deepLinkImportMessage => '确定要导入此订阅吗？';

  @override
  String get deepLinkImportNameLabel => '名称';

  @override
  String get deepLinkImportAction => '导入';

  @override
  String get deepLinkImportSourceLabel => '来源链接';

  @override
  String get deepLinkImportResolvedUrlLabel => '解析后的订阅 URL';

  @override
  String get deepLinkImportUserAgentLabel => 'User-Agent';

  @override
  String get deepLinkImportHwidLabel => 'HWID';

  @override
  String get deepLinkImportHwidValue => '将在确认后发送';

  @override
  String deepLinkImportSuccess(String name) {
    return '订阅「$name」已导入';
  }

  @override
  String deepLinkImportAlreadyExists(String name) {
    return '订阅“$name”已添加';
  }

  @override
  String get subscriptionOperationSlowWarning => '订阅服务器响应比平时慢。如果持续出现，请检查链接或网络。';

  @override
  String get subscriptionOperationTimeout => '订阅服务器未及时响应。请检查链接或网络后重试。';

  @override
  String get continueAction => '继续';

  @override
  String get routingTitle => '路由';

  @override
  String get routingSubtitle => '流量路由规则';

  @override
  String get bypassLocalNetworkTitle => '绕过本地网络';

  @override
  String get bypassLocalNetworkSubtitle => '私有与局域网地址直接路由';

  @override
  String get adBlockTitle => '广告拦截';

  @override
  String get adBlockSubtitle => '客户端将自行下载本地规则集并接入路由。';

  @override
  String get adBlockDownloadAction => '下载';

  @override
  String get adBlockDownloadAndEnableAction => '下载并启用';

  @override
  String get adBlockUpdateAction => '更新';

  @override
  String get adBlockEnableTitle => '启用本地拦截';

  @override
  String get adBlockEnabledSubtitle => '使用已下载的本地规则集进行 DNS 与路由拦截。';

  @override
  String get adBlockMissingSubtitle => '请先下载过滤器包才能使用。';

  @override
  String get adBlockDownloadingStatus => '正在下载并构建本地过滤器…';

  @override
  String get adBlockDeletingStatus => '正在删除过滤器…';

  @override
  String get adBlockStageConnecting => '正在连接 AdGuard…';

  @override
  String get adBlockStageDownloading => '正在下载过滤器列表…';

  @override
  String get adBlockStageCompiling => '正在构建本地规则集…';

  @override
  String get adBlockStageActivating => '正在安全替换规则集…';

  @override
  String get adBlockStageComplete => '过滤器已更新';

  @override
  String get adBlockPreparingHint => '正在准备下载……';

  @override
  String adBlockDownloadedProgress(String completed) {
    return '已下载 $completed';
  }

  @override
  String adBlockDownloadProgress(String completed, String total) {
    return '$completed / $total';
  }

  @override
  String adBlockDownloadProgressEta(
    String completed,
    String total,
    int seconds,
  ) {
    return '已完成 $completed/$total，还剩约 $seconds 秒';
  }

  @override
  String get adBlockMissingStatus => '过滤器尚未下载';

  @override
  String get adBlockMissingHint => '下载 AdGuard 过滤器以启用拦截。过滤器将保存在此设备上。';

  @override
  String adBlockReadyStatus(int blockedCount) {
    return '过滤器已就绪，域名数：$blockedCount';
  }

  @override
  String adBlockMeta(String updatedAt, int allowedCount) {
    return '更新时间：$updatedAt · 例外：$allowedCount';
  }

  @override
  String get splitRoutingTitle => '分应用路由';

  @override
  String get splitRoutingSubtitle => '选择哪些应用走 VPN，哪些直连。';

  @override
  String get splitRoutingUnavailableTitle => '暂时不可用';

  @override
  String get splitRoutingUnavailableMessage => '分应用代理目前无法正常工作，我们正在修复，请关注更新。';

  @override
  String get splitRoutingTunOnly => '仅在 VPN 模式下可用。本地代理模式无法管理应用。';

  @override
  String get splitRoutingModeTitle => '模式';

  @override
  String get splitRoutingModeDisabled => '关闭';

  @override
  String get splitRoutingModeDisabledSubtitle => '未使用分流';

  @override
  String get splitRoutingModeProxySelected => '走 VPN';

  @override
  String get splitRoutingModeProxySelectedSubtitle => '仅所选应用使用 VPN';

  @override
  String get splitRoutingModeBypassSelected => 'VPN 之外';

  @override
  String get splitRoutingModeBypassSelectedSubtitle => '所选应用直连';

  @override
  String get splitRoutingLockdownWarning =>
      '开启 Android 的「始终开启 VPN」并勾选「阻止未通过 VPN 的连接」后，被设为不走 VPN 的应用可能会无法联网。';

  @override
  String get splitRoutingAppsTitle => '应用';

  @override
  String get splitRoutingAppVisibilityNotice =>
      'Android 仅为选择应用而向 Etonify 提供已安装应用列表，该列表仅保留在本设备上。';

  @override
  String get splitRoutingPackagesTitle => '包名';

  @override
  String get splitRoutingPackagesHint => 'com.termux\norg.mozilla.firefox';

  @override
  String get splitRoutingPackagesHelper => '包名，例如 org.telegram.messenger';

  @override
  String get splitRoutingPickAppsAction => '选择应用';

  @override
  String get splitRoutingPickAppsTitle => '选择应用';

  @override
  String get splitRoutingSearchHint => '按应用或包名搜索';

  @override
  String get splitRoutingAndroidOnly => '应用选择器仅在安卓上可用';

  @override
  String get splitRoutingLoadAppsFailed => '加载已安装应用失败';

  @override
  String splitRoutingSelectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String get splitRoutingNoAppsTitle => '尚未选择应用';

  @override
  String get splitRoutingNoAppsSubtitle => '为此模式选择应用';

  @override
  String get splitRoutingManualEditorTitle => '手动包名列表';

  @override
  String get splitRoutingManualEditorSubtitle => '手动输入包名';

  @override
  String refreshIntervalDaysShort(int count) {
    return '$count 天';
  }

  @override
  String refreshIntervalHoursShort(int count) {
    return '$count 小时';
  }

  @override
  String refreshIntervalMinutesShort(int count) {
    return '$count 分钟';
  }

  @override
  String get subscriptionLikelyRequiresHwidTitle => '可能需要 HWID';

  @override
  String get subscriptionLikelyRequiresHwidWarning =>
      '此订阅可能需要 HWID。服务器仅返回了一个名称含 app/HWID 的出站。请打开订阅设置并启用 HWID 发送。';

  @override
  String get subscriptionLikelyRequiresHwidMessage =>
      '服务器仅返回了一个出站，且其名称像是与应用或 HWID 相关的占位符。\n\n这通常意味着订阅要求在请求中携带设备 HWID。\n\n是否现在启用 HWID 发送并重新更新订阅？';

  @override
  String get subscriptionLikelyRequiresHwidAction => '启用 HWID';

  @override
  String get subscriptionHwidEnabledAndUpdated => '已启用 HWID 发送，订阅已更新。';

  @override
  String get noValidOutboundsTitle => '没有可用节点';

  @override
  String get noValidOutboundsWarning => '此订阅中没有可用的出站，均已在校验时被过滤。请检查或更新订阅。';

  @override
  String get noValidOutboundsMessage =>
      '该订阅已没有可用的出站。\n\n所有节点在启动前的校验中均被过滤，因此客户端不会以空代理集合启动 sing-box。\n\n请检查订阅、刷新后重试，或导入有效的订阅。';

  @override
  String get noValidOutboundsAfterDropInvalidWarning =>
      '剔除无效节点后，所选订阅中已没有可用的出站。请检查该订阅，它可能有问题。';

  @override
  String get noValidOutboundsAfterDropInvalidMessage =>
      '启动时所选订阅中剩余的节点均被判定为无效并丢弃。\n\n客户端已在将损坏的配置交给 sing-box 之前停止。\n\n请检查订阅内容并更新或替换。';

  @override
  String get experimentalTcpFastOpenTitle => 'TCP Fast Open';

  @override
  String get experimentalTcpFastOpenSubtitle => '可能缩短 TCP 握手时间，但支持情况取决于网络与服务器。';

  @override
  String get experimentalTcpMultiPathTitle => 'TCP 多路径';

  @override
  String get experimentalTcpMultiPathSubtitle =>
      '尝试多条网络路径。可能有助于网络切换，但可能导致手机发热或运行不稳定。';

  @override
  String get experimentalInterruptConnectionsTitle => '切换节点时中断活动连接';

  @override
  String get experimentalInterruptConnectionsSubtitle =>
      '更快应用代理变更，但旧的应用连接可能被中断。';

  @override
  String get experimentalUrlTestStrictToleranceTitle => 'URLTest 1 毫秒容差';

  @override
  String get experimentalUrlTestStrictToleranceSubtitle =>
      '更严格地选择最低延迟的代理，但可能会更频繁地切换服务器。';

  @override
  String get experimentalFakeIpTitle => '改写 DNS 应答（FakeIP）';

  @override
  String get experimentalFakeIpSubtitle => '加速 VPN TUN 内的域名处理。部分应用可能不兼容。';

  @override
  String get experimentalFakeIpUnavailableSubtitle =>
      '仅在开启 VPN TUN 且关闭分应用路由时可用。';

  @override
  String get tlsFragmentationTitle => 'TLS 分片';

  @override
  String get tlsFragmentationSubtitle =>
      '对代理出站进行 TLS 握手分片。有助于对抗 DPI，但可能减慢连接建立速度。';

  @override
  String get tlsFragmentationModeDisabled => '已禁用';

  @override
  String get tlsFragmentationModeDisabledSubtitle => '不更改服务器 TLS 设置。';

  @override
  String get tlsFragmentationModeRecord => 'TLS 记录分片';

  @override
  String get tlsFragmentationModeRecordSubtitle => '更温和的模式，建议优先尝试。';

  @override
  String get tlsFragmentationModeFragment => 'TLS 分片';

  @override
  String get tlsFragmentationModeFragmentSubtitle => '更激进的模式，备用延迟为 300 毫秒。';

  @override
  String get blockLeaksTitle => '修复部分泄漏';

  @override
  String get blockLeaksSubtitle => '仅拦截可能绕过代理的 STUN/WebRTC 流量';

  @override
  String get addSubscriptionCaption => '通过链接或文件添加订阅';

  @override
  String get pasteSubscriptionLink => '粘贴订阅链接';

  @override
  String get orManually => '或手动';

  @override
  String get pasteAction => '粘贴';

  @override
  String get cancelAction => '取消';

  @override
  String get settingsMenuImport => '导入';

  @override
  String get settingsMenuExport => '导出';

  @override
  String get settingsResetAction => '重置设置';

  @override
  String get settingsResetTitle => '重置设置？';

  @override
  String get settingsResetMessage => '所有客户端设置将恢复为默认值。订阅和已选服务器将保留。';

  @override
  String get settingsResetSuccess => '设置已恢复默认';

  @override
  String get backupExportSettings => '导出设置';

  @override
  String get backupExportProfileEncrypted => '带密码导出订阅';

  @override
  String get backupExportProfilePlain => '不加密导出订阅';

  @override
  String get backupPlainWarningTitle => '文件将包含 VPN 密钥';

  @override
  String get backupPlainWarningMessage =>
      '明文导出文件可被任何获取该文件的人读取。除非您完全信任存储与传输途径，否则请使用加密导出。';

  @override
  String get backupPlainImportTitle => '明文配置文件';

  @override
  String get backupPlainImportMessage => '此文件包含未加密的订阅和 VPN 密钥。仅在信任来源时导入。';

  @override
  String get backupPasswordCreateTitle => '创建导出密码';

  @override
  String get backupPasswordEnterTitle => '输入配置密码';

  @override
  String get backupPasswordHint => '密码';

  @override
  String get backupSaved => '备份文件已保存';

  @override
  String get backupImported => '导入完成';

  @override
  String get backupUnsupportedVersion => '此客户端版本不支持该备份格式。';

  @override
  String get backupNewerVersionTitle => '来自更新客户端的备份';

  @override
  String backupNewerVersionMessage(String version) {
    return '此文件由 Etonify $version 创建。部分设置可能无法正确应用。继续吗？';
  }

  @override
  String get splitRoutingEmptyWhitelist => '启动 VPN 前请至少选择一个应用，或关闭分应用代理。';

  @override
  String get splitRoutingUnknownAppLabel => '未找到应用';

  @override
  String get splitRoutingLoadingAppLabel => '正在查找应用…';

  @override
  String get connectionStagePreparing => '正在准备 VPN';

  @override
  String get connectionStageConfiguring => '正在构建配置';

  @override
  String get connectionStageStarting => '正在启动核心';

  @override
  String get connectionStageStopping => '正在停止 VPN';

  @override
  String get connectionStageRecovering => '正在恢复';

  @override
  String get connectionStageSelectingProxy => '正在选择服务器';

  @override
  String get vpnStartTimedOut => 'VPN 未在 15 秒内启动，已停止启动。';

  @override
  String get vpnStartFailed => 'VPN 启动失败。';

  @override
  String get logsJumpToLatest => '跳到最新日志';

  @override
  String proxyOpenGroup(String name) {
    return '打开分组：$name';
  }

  @override
  String get proxyGroupNoAvailableServersMessage => '该分组中没有可用服务器，请尝试其他分组或重新检测。';

  @override
  String get remoteDownloadConnectTimeout => '5 秒内未能连接到服务器。请检查网络或已启用的 VPN 后重试。';

  @override
  String get remoteDownloadResponseTimeout => '服务器 5 秒内未开始响应。请检查网络或当前 VPN 后重试。';

  @override
  String get remoteDownloadRetryWithoutVpn => '尝试不走 VPN';

  @override
  String get remoteDownloadRetryWithoutVpnHint =>
      'VPN 路由无响应。正经由 Wi-Fi 或移动数据重试。';

  @override
  String get remoteDownloadIdleTimeout => '服务器 7 秒未发送数据，下载已停止，请重试。';

  @override
  String get routingRuleFilesTitle => '中国路由数据';

  @override
  String get routingRuleFilesSettingsTitle => '中国路由数据';

  @override
  String routingRuleFilesSettingsReady(int count) {
    return '$count 个文件已就绪';
  }

  @override
  String get routingRuleFilesSettingsPreparing => '将自动准备中国域名和 IP 数据';

  @override
  String get routingRuleFilesReadyTitle => '中国路由数据已就绪';

  @override
  String get routingRuleFilesReadySubtitle => '域名和 IP 规则集保存在本机，可离线使用。';

  @override
  String get routingRuleFilesPreparingTitle => '正在准备中国路由数据';

  @override
  String get routingRuleFilesPreparingSubtitle => '正在下载最新的中国域名与 IP 规则集。';

  @override
  String get routingRuleFilesSourceTitle => '来源';

  @override
  String get routingRuleFilesVersionTitle => '版本';

  @override
  String get routingRuleFilesCountTitle => '文件';

  @override
  String get routingRuleFilesTotalSizeTitle => '总大小';

  @override
  String get routingRuleFilesScopeTitle => '中国域名和 IP 网段';

  @override
  String get routingRuleFilesScopeSubtitle =>
      '规则模式下，中国域名和 IP 网段直连；其余未匹配流量走当前代理。';

  @override
  String get routingRuleFilesOpenSourceFailed => '无法打开来源页面，请重试。';

  @override
  String routingRuleFilesSourceMeta(String source, String version, int count) {
    return '来源：$source · 版本：$version · 文件：$count';
  }

  @override
  String get routingRuleFilesUpdateAction => '更新文件';

  @override
  String get routingRuleFilesUpdatingAction => '正在更新文件……';

  @override
  String routingRuleFilesEta(String duration) {
    return '大约还剩 $duration';
  }

  @override
  String routingRuleFilesSecondsShort(int seconds) {
    return '$seconds 秒';
  }

  @override
  String routingRuleFilesMinutesShort(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get routingRuleFilesListTitle => '规则文件';

  @override
  String get routingRuleFilesEmptyTitle => '文件尚未就绪';

  @override
  String get routingRuleFilesEmptySubtitle => '请重新打开此页面或点击“更新文件”。';

  @override
  String get coreIntegrationTitle => '核心与配置';

  @override
  String get coreIntegrationSubtitle => '显示内置核心和上次应用配置的实际状态，而不仅是应用界面上的开关。';

  @override
  String get coreApiLabel => '核心 API';

  @override
  String get coreCompatibilityLabel => '兼容性';

  @override
  String get coreCompatible => '兼容';

  @override
  String get coreIncompatible => '不兼容';

  @override
  String get coreConfigStateLabel => '配置状态';

  @override
  String get coreConfigApplied => '已应用';

  @override
  String get coreConfigValidated => '已验证';

  @override
  String get coreConfigFailed => '失败';

  @override
  String get coreConfigSuperseded => '已被取代';

  @override
  String get coreConfigNotApplied => '尚未应用';

  @override
  String get coreConfigPending => '正在应用…';

  @override
  String get coreRuntimeStateLabel => 'VPN 状态';

  @override
  String get coreRuntimeRunning => '运行中';

  @override
  String get coreRuntimeStopped => '已停止';

  @override
  String get coreRuntimeGenerationLabel => '运行时生成';

  @override
  String get coreConfigSchemaLabel => '配置架构';

  @override
  String get coreLastChangeLabel => '上次应用';

  @override
  String get splitRoutingApply => '应用';

  @override
  String get splitRoutingEnabled => '应用路由';

  @override
  String get splitRoutingSystemApps => '系统应用';

  @override
  String get splitRoutingOnlySelected => '仅选中项';

  @override
  String get splitRoutingResetTitle => '应用路由已重置';

  @override
  String get splitRoutingResetFailed => '无法完成重置。自动连接仍处于暂停状态，请尝试再次点击连接。';

  @override
  String get splitRoutingResetMessage =>
      '界面已重新设计。此前的选择已清空，分应用路由已禁用。请为每种模式分别选择应用。VPN 已停止，以避免在未经您确认的情况下更改应用路由。';

  @override
  String get splitRoutingResetPageMessage =>
      '界面已重新设计，之前的选择已被重置一次。请分别配置每种模式，新的选择将被保留。';

  @override
  String get splitRoutingConfigure => '配置';

  @override
  String get splitRoutingLater => '稍后';

  @override
  String get splitRoutingRulesHint => '进入 VPN 的应用仍遵循流量规则。直连规则可以绕过所选代理。';

  @override
  String get splitRoutingLimit => '每种模式最多选择 128 个应用。';

  @override
  String get splitRoutingUnsavedTitle => '有未保存的更改';

  @override
  String get splitRoutingUnsavedMessage => '离开前请应用更改或将其舍弃。';

  @override
  String get splitRoutingDiscard => '放弃';

  @override
  String get splitRoutingApplyFailed => '无法应用或保存设置。请检查网络后重试。';

  @override
  String get routingBlockLeaksCompact => '阻止 STUN/WebRTC';

  @override
  String get routingBlockLeaksSummary => '减少通过 WebRTC 绕过代理的流量';

  @override
  String get routingBypassLocalSummary => '仅规则模式生效；全局模式会让隧道流量走当前代理。';

  @override
  String get routingAdBlockSummary => '本地域名过滤';

  @override
  String get batteryOptimizationTitle => '电池优化';

  @override
  String get batteryOptimizationExempt => '后台无限制访问';

  @override
  String get batteryOptimizationRestricted => '后台访问受限';

  @override
  String get batteryOptimizationUnavailable => '此设备不支持';

  @override
  String get batteryOptimizationChecking => '正在检查系统设置…';

  @override
  String get batteryOptimizationDescription =>
      '如果熄屏后 VPN 断开，请允许后台运行。这可能会增加耗电；你的设备可能还有其他限制。';

  @override
  String get batteryOptimizationOpenFailed => '无法打开电池设置。请从安卓设置中打开。';

  @override
  String get routingModeTitle => '流量路由模式';

  @override
  String get routingModeRules => '规则';

  @override
  String get routingModeGlobal => '全局';

  @override
  String get routingModeRulesDescription =>
      '中国域名和 IP 网段直连；你添加的规则优先，其余未匹配流量走当前代理。';

  @override
  String get routingModeGlobalDescription =>
      'Etonify 接管的流量全部走当前代理，忽略域名/IP规则和局域网直连；按应用分流仍然生效。';

  @override
  String get routingModePreparingChinaData => '正在准备中国域名和 IP 规则…';

  @override
  String get routingModeChinaDataFailedHint =>
      '暂时无法获取中国规则数据。规则模式仍已启用，未匹配流量会安全地回退到代理。';

  @override
  String get googlePlayPresetTitle => '中国 Play 商店规则';

  @override
  String get googlePlayPresetSubtitle =>
      '将 Google Play 应用及相关域名通过当前代理。SagerNet geosite 在线下载、缓存并按日更新；数据暂不可用时，应用包名与明确域名规则仍生效。仅在“规则”模式下生效。';

  @override
  String get customRoutingRulesTitle => '自定义域名和 IP 规则';

  @override
  String get customRoutingRulesDescription =>
      '自定义规则优先于中国直连规则；未匹配流量走代理。全局模式会忽略这些规则。可调整规则顺序来设置优先级。';

  @override
  String get customRoutingRulesEmptyTitle => '还没有自定义规则';

  @override
  String get customRoutingRulesEmptySubtitle => '添加域名或 IP 网段，并选择它走代理还是直连。';

  @override
  String customRoutingRulesCount(int count) {
    return '$count 条规则';
  }

  @override
  String customRoutingRulesLimit(int count) {
    return '最多可添加 $count 条规则。';
  }

  @override
  String get customRoutingRuleAdd => '添加规则';

  @override
  String get customRoutingRuleAddTitle => '添加路由规则';

  @override
  String get customRoutingRuleEditTitle => '编辑路由规则';

  @override
  String get customRoutingRuleActions => '规则操作';

  @override
  String get customRoutingRuleType => '匹配类型';

  @override
  String get customRoutingRuleDomain => '域名';

  @override
  String get customRoutingRuleIp => 'IP 地址或网段';

  @override
  String get customRoutingRuleDomainLabel => '域名';

  @override
  String get customRoutingRuleIpLabel => 'IP 地址或网段';

  @override
  String get customRoutingRuleDomainHint => 'example.com 或 *.example.com';

  @override
  String get customRoutingRuleIpHint => '203.0.113.0/24 或 2001:db8::/32';

  @override
  String get customRoutingRuleTarget => '路由方式';

  @override
  String get customRoutingRuleProxy => '走代理';

  @override
  String get customRoutingRuleDirect => '直连';

  @override
  String get customRoutingRuleInvalidDomain => '请输入有效域名，例如 example.com。';

  @override
  String get customRoutingRuleInvalidIp => '请输入有效的 IPv4/IPv6 地址或 CIDR 网段。';

  @override
  String get customRoutingRuleInvalidValue => '规则内容无效。';

  @override
  String get customRoutingRuleDuplicate => '该域名或 IP 已有规则。';

  @override
  String get customRoutingRuleSave => '保存';

  @override
  String get customRoutingRuleEdit => '编辑';

  @override
  String get customRoutingRuleDelete => '删除';

  @override
  String get customRoutingRuleMoveUp => '上移（提高优先级）';

  @override
  String get customRoutingRuleMoveDown => '下移（降低优先级）';

  @override
  String get routingRuleFilesUpdateFailed => '无法准备中国规则数据，请检查网络后重试。';

  @override
  String get routingRuleFilesPreparingHint => '正在下载并校验中国域名和 IP 规则集…';

  @override
  String routingRuleFilesDownloadProgress(String completed, String total) {
    return '已下载 $completed / 共 $total。';
  }

  @override
  String routingRuleFilesItemsProgress(int completed, int total) {
    return '已处理 $completed / 共 $total 项。';
  }

  @override
  String routingRuleFilesItemsProcessed(int completed) {
    return '已处理 $completed 项。';
  }

  @override
  String get routingRuleFilesStageChecking => '正在检查中国规则数据…';

  @override
  String get routingRuleFilesStageDownloading => '正在下载中国规则数据…';

  @override
  String get routingRuleFilesStageVerifying => '正在校验规则文件…';

  @override
  String get routingRuleFilesStageExtracting => '正在准备规则文件…';

  @override
  String get routingRuleFilesStageCategories => '正在更新规则数据…';

  @override
  String get routingRuleFilesStageCompiling => '正在检查本地规则…';

  @override
  String get routingRuleFilesStageActivating => '正在应用规则数据…';

  @override
  String get routingRuleFilesStageComplete => '中国规则数据已就绪';

  @override
  String get verifiedBadgeTooltip => '已认证';
}
