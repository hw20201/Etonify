import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/data/routing/custom_routing_rule.dart';

void main() {
  group('CustomRoutingRule', () {
    test('normalizes domain suffixes and creates proxy/direct rules', () {
      final domain = CustomRoutingRule.create(
        type: CustomRouteRuleType.domain,
        value: '*.ExAmple.com.',
        action: CustomRouteAction.proxy,
      );
      final ip = CustomRoutingRule.create(
        type: CustomRouteRuleType.ip,
        value: '203.0.113.7/24',
        action: CustomRouteAction.direct,
      );

      expect(domain.value, 'example.com');
      expect(domain.toSingboxRouteRule(outbound: 'select'), {
        'domain_suffix': ['example.com'],
        'outbound': 'select',
      });
      expect(domain.toSingboxDnsRule(server: 'dns-remote'), {
        'domain_suffix': ['example.com'],
        'action': 'route',
        'server': 'dns-remote',
      });
      expect(ip.value, '203.0.113.7/24');
      expect(ip.toSingboxRouteRule(outbound: 'direct'), {
        'ip_cidr': ['203.0.113.7/24'],
        'outbound': 'direct',
      });
    });

    test('accepts IPv6 CIDR and validates prefix bounds', () {
      final rule = CustomRoutingRule.create(
        type: CustomRouteRuleType.ip,
        value: '2001:DB8::1/64',
        action: CustomRouteAction.proxy,
      );
      expect(rule.value, '2001:db8::1/64');
      expect(
        () => CustomRoutingRule.create(
          type: CustomRouteRuleType.ip,
          value: '192.0.2.1/33',
          action: CustomRouteAction.direct,
        ),
        throwsFormatException,
      );
    });

    test('rejects URL syntax, path, port, whitespace, and invalid domains', () {
      for (final value in [
        'https://example.com',
        'example.com/path',
        'example.com:443',
        'bad domain.example',
        '-invalid.example',
      ]) {
        expect(
          () => CustomRoutingRule.create(
            type: CustomRouteRuleType.domain,
            value: value,
            action: CustomRouteAction.proxy,
          ),
          throwsFormatException,
          reason: 'should reject $value',
        );
      }
    });

    test('storage decoding ignores invalid entries and deduplicates rules', () {
      final decoded = CustomRoutingRule.decodeStorage(
        jsonEncode([
          {'type': 'domain', 'value': 'example.com', 'action': 'proxy'},
          {'type': 'domain', 'value': '*.EXAMPLE.COM', 'action': 'direct'},
          {'type': 'nope', 'value': 'bad.example', 'action': 'proxy'},
        ]),
      );

      expect(decoded, hasLength(1));
      expect(decoded.single.value, 'example.com');
      expect(decoded.single.action, CustomRouteAction.direct);
      expect(CustomRoutingRule.decodeStorage('not json'), isEmpty);
    });
  });
}
