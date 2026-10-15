import 'dart:convert';
import 'dart:io';

enum CustomRouteRuleType { domain, ip }

enum CustomRouteAction { proxy, direct }

const int maxCustomRouteRuleCount = 256;

final RegExp _domainLabelPattern = RegExp(
  r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
);
final RegExp _decimalPrefixPattern = RegExp(r'^\d+$');

class CustomRoutingRule {
  const CustomRoutingRule._({
    required this.type,
    required this.value,
    required this.action,
  });

  factory CustomRoutingRule.create({
    required CustomRouteRuleType type,
    required String value,
    required CustomRouteAction action,
  }) {
    final normalized = switch (type) {
      CustomRouteRuleType.domain => _normalizeDomain(value),
      CustomRouteRuleType.ip => _normalizeIpCidr(value),
    };
    return CustomRoutingRule._(type: type, value: normalized, action: action);
  }

  final CustomRouteRuleType type;
  final String value;
  final CustomRouteAction action;

  String get key => '${type.name}:$value';

  Map<String, Object> toJson() => <String, Object>{
    'type': type.name,
    'value': value,
    'action': action.name,
  };

  Map<String, Object> toSingboxRouteRule({required String outbound}) =>
      switch (type) {
        CustomRouteRuleType.domain => <String, Object>{
          'domain_suffix': <String>[value],
          'outbound': outbound,
        },
        CustomRouteRuleType.ip => <String, Object>{
          'ip_cidr': <String>[value],
          'outbound': outbound,
        },
      };

  Map<String, Object> toSingboxDnsRule({required String server}) => {
    'domain_suffix': <String>[value],
    'action': 'route',
    'server': server,
  };

  static List<CustomRoutingRule> decodeStorage(Object? raw) {
    Object? decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return const <CustomRoutingRule>[];
      }
    }
    if (decoded is! Iterable) return const <CustomRoutingRule>[];

    final parsed = <CustomRoutingRule>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final type = switch (item['type']?.toString()) {
        'domain' => CustomRouteRuleType.domain,
        'ip' => CustomRouteRuleType.ip,
        _ => null,
      };
      final action = switch (item['action']?.toString()) {
        'proxy' => CustomRouteAction.proxy,
        'direct' => CustomRouteAction.direct,
        _ => null,
      };
      if (type == null || action == null) continue;
      try {
        parsed.add(
          CustomRoutingRule.create(
            type: type,
            value: item['value']?.toString() ?? '',
            action: action,
          ),
        );
      } on FormatException {
        // Ignore invalid entries from old or manually edited backups.
      }
    }
    return normalizeCustomRoutingRules(parsed);
  }

  static List<CustomRoutingRule> normalizeCustomRoutingRules(
    Iterable<CustomRoutingRule> rules,
  ) {
    final normalized = <CustomRoutingRule>[];
    final indexes = <String, int>{};
    for (final rule in rules) {
      final index = indexes[rule.key];
      if (index != null) {
        normalized[index] = rule;
        continue;
      }
      if (normalized.length >= maxCustomRouteRuleCount) break;
      indexes[rule.key] = normalized.length;
      normalized.add(rule);
    }
    return List<CustomRoutingRule>.unmodifiable(normalized);
  }

  static String _normalizeDomain(String input) {
    var candidate = input.trim().toLowerCase();
    if (candidate.startsWith('*.')) candidate = candidate.substring(2);
    if (candidate.isEmpty ||
        candidate.contains(RegExp(r'[\s/:?#@\\]')) ||
        candidate.contains('://')) {
      throw const FormatException('Enter a valid domain name.');
    }

    final uri = Uri.tryParse(
      candidate.contains('://') ? candidate : 'https://$candidate',
    );
    if (uri == null || uri.host.isEmpty) {
      throw const FormatException('Enter a valid domain name.');
    }
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    if (host.isEmpty ||
        host.length > 253 ||
        InternetAddress.tryParse(host) != null) {
      throw const FormatException('Enter a valid domain name.');
    }
    final labels = host.split('.');
    if (labels.any(
      (label) =>
          label.isEmpty ||
          label.length > 63 ||
          !_domainLabelPattern.hasMatch(label),
    )) {
      throw const FormatException('Enter a valid domain name.');
    }
    return host;
  }

  static String _normalizeIpCidr(String input) {
    final candidate = input.trim();
    if (candidate.isEmpty ||
        candidate.contains(RegExp(r'\s')) ||
        candidate.contains('%')) {
      throw const FormatException('Enter a valid IP address or CIDR.');
    }
    final parts = candidate.split('/');
    if (parts.length > 2) {
      throw const FormatException('Enter a valid IP address or CIDR.');
    }
    final address = InternetAddress.tryParse(parts.first);
    if (address == null) {
      throw const FormatException('Enter a valid IP address or CIDR.');
    }
    final bitCount = address.type == InternetAddressType.IPv4 ? 32 : 128;
    final prefix = parts.length == 1
        ? bitCount
        : _decimalPrefixPattern.hasMatch(parts.last)
        ? int.tryParse(parts.last)
        : null;
    if (prefix == null || prefix < 0 || prefix > bitCount) {
      throw const FormatException('Enter a valid IP address or CIDR.');
    }
    return '${address.address.toLowerCase()}/$prefix';
  }
}
