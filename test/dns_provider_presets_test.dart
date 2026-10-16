import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/app/app_settings_controller.dart';

void main() {
  const presets = <String, String>{
    'google': 'udp://8.8.8.8',
    'google_dot': 'tls://dns.google',
    'google_doh': 'https://dns.google/dns-query',
    'quad9': 'udp://9.9.9.9',
    'quad9_dot': 'tls://dns.quad9.net',
    'quad9_doh': 'https://dns.quad9.net/dns-query',
    'adguard': 'udp://94.140.14.14',
    'adguard_dot': 'tls://dns.adguard-dns.com',
    'adguard_doh': 'https://dns.adguard-dns.com/dns-query',
  };

  for (final entry in presets.entries) {
    test('DNS preset ${entry.key} sets the direct and proxy resolvers', () {
      final controller = AppSettingsController();

      controller.setDnsDirectPreset(entry.key);
      controller.setDnsProxyPreset(entry.key);

      expect(controller.dnsDirectPreset, entry.key);
      expect(controller.dnsDirectResolver, entry.value);
      expect(controller.dnsProxyPreset, entry.key);
      expect(controller.dnsProxyResolver, entry.value);
    });
  }
}
