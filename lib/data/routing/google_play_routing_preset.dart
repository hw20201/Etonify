import 'package:meow_client/data/routing/custom_routing_rule.dart';

/// Android packages displayed as Google Play 商店 and Google Play 服务.
const List<String> googlePlayPresetPackageNames = <String>[
  'com.android.vending',
  'com.google.android.gms',
];

/// Explicit NekoBox-style proxy domains from the supplied rule list.
const List<String> googlePlayPresetDomainSuffixes = <String>[
  'googleapis.cn',
  'xn--ngstr-lra8j.com',
  'xn--ngstr-cn-8za9o.com',
  'gvt1.com',
  'gvt2.com',
  'gvt3.com',
  'gvt5.com',
  'gvt6.com',
];

const String googlePlayGeositeUrl =
    'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-google-play.srs';
const String googleCnGeositeUrl =
    'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-google@cn.srs';

const String googlePlayPresetGeositeTag = 'sagernet-geosite-google-play';
const String googleCnPresetGeositeTag = 'sagernet-geosite-google-cn';

const List<String> googlePlayPresetGeositeTags = <String>[
  googlePlayPresetGeositeTag,
  googleCnPresetGeositeTag,
];

/// One-time additive custom proxy rules. Appending after existing entries lets
/// these three requested domains override a preexisting direct rule with the
/// same normalized key while preserving every other user rule.
final List<CustomRoutingRule> googlePlayCustomProxyRules =
    List<CustomRoutingRule>.unmodifiable(<CustomRoutingRule>[
      CustomRoutingRule.create(
        type: CustomRouteRuleType.domain,
        value: 'dl.google.com',
        action: CustomRouteAction.proxy,
      ),
      CustomRoutingRule.create(
        type: CustomRouteRuleType.domain,
        value: 'play.google.com',
        action: CustomRouteAction.proxy,
      ),
      CustomRoutingRule.create(
        type: CustomRouteRuleType.domain,
        value: 'play.googleapis.com',
        action: CustomRouteAction.proxy,
      ),
    ]);

List<CustomRoutingRule> mergeGooglePlayCustomProxyRules(
  Iterable<CustomRoutingRule> existingRules,
) => CustomRoutingRule.normalizeCustomRoutingRules(<CustomRoutingRule>[
  ...existingRules,
  ...googlePlayCustomProxyRules,
]);
