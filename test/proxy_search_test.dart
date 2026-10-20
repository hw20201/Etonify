import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/proxies/proxy_search.dart';
import 'package:meow_client/models/app_view_models.dart';

AppProxySummary proxy({
  String name = 'Tokyo Fast',
  String protocol = 'VLESS',
  String country = 'JP',
  bool group = false,
}) => AppProxySummary(
  tag: name,
  displayName: name,
  countryCode: country,
  type: protocol,
  server: 'example.net',
  port: 443,
  detailText: 'TLS Reality',
  ip: '',
  latency: null,
  latencyFresh: false,
  latencyChecking: false,
  latencyUnavailable: false,
  latencyError: null,
  protocolLabel: protocol,
  endpointLabel: 'example.net:443',
  isGroup: group,
);

void main() {
  test('matches display metadata case-insensitively and clears cleanly', () {
    final item = proxy();
    expect(proxyMatchesSearch(item, 'tokYO'), isTrue);
    expect(proxyMatchesSearch(item, 'vless'), isTrue);
    expect(proxyMatchesSearch(item, 'jp'), isTrue);
    expect(proxyMatchesSearch(item, 'not present'), isFalse);
    expect(proxyMatchesSearch(item, '  '), isTrue);
  });

  test('group remains visible when a child matches', () {
    final group = proxy(name: 'Europe', group: true);
    final child = proxy(name: 'Berlin 01', country: 'DE');
    expect(proxyOrChildMatchesSearch(group, 'berlin', [child]), isTrue);
    expect(proxyOrChildMatchesSearch(group, 'unmatched', [child]), isFalse);
  });
}
