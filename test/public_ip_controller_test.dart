import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';

PublicIpInfo _info(String ip, {String countryCode = 'SE'}) => PublicIpInfo(
  ip: ip,
  countryCode: countryCode,
  organization: 'Example Org',
  asn: 'AS64500',
);

void main() {
  test('ipquery JSON normalizes country and exposes risk/network fields', () {
    final info = PublicIpInfo.fromIpQueryJson({
      'ip': '203.0.113.8',
      'isp': {'asn': 'AS64500', 'org': 'Example Org', 'isp': 'Example ISP'},
      'location': {
        'country_code': 'se',
        'country': 'Sweden',
        'city': 'Stockholm',
      },
      'risk': {
        'risk_score': 12,
        'is_mobile': false,
        'is_vpn': true,
        'is_tor': false,
        'is_proxy': false,
        'is_datacenter': true,
      },
    });
    expect(info.countryCode, 'SE');
    expect(info.country, 'Sweden');
    expect(info.city, 'Stockholm');
    expect(info.organization, 'Example Org');
    expect(info.asn, 'AS64500');
    expect(info.riskScore, 12);
    expect(info.networkType, PublicIpNetworkType.vpn);
    expect(info.source, PublicIpSource.ipQuery);
  });

  test('invalid IPs and malformed source records are rejected', () {
    expect(
      () => PublicIpInfo.fromIpQueryJson({'ip': 'not-an-ip'}),
      throwsFormatException,
    );
    expect(
      () => PublicIpInfo.fromIpApiJson({'status': 'fail'}),
      throwsFormatException,
    );
    expect(
      () => PublicIpInfo.fromIpApiJson({
        'status': 'success',
        'query': '192.0.2.1',
        'countryCode': 'XX',
        'as': 'AS64501 Example ASN',
        'proxy': true,
      }),
      returnsNormally,
    );
    final fallback = PublicIpInfo.fromIpApiJson({
      'status': 'success',
      'query': '192.0.2.1',
      'countryCode': 'XX',
      'as': 'AS64501 Example ASN',
      'proxy': true,
    });
    expect(fallback.countryCode, isEmpty);
    expect(fallback.asn, 'AS64501');
    expect(fallback.isProxy, isTrue);
    expect(fallback.source, PublicIpSource.ipApi);
  });

  testWidgets('refresh gates repeated calls for four seconds', (tester) async {
    var calls = 0;
    final controller = PublicIpController(
      load: () async {
        calls++;
        return _info('203.0.113.$calls');
      },
    );
    await controller.refresh();
    await controller.refresh();
    expect(controller.info?.ip, '203.0.113.1');
    await tester.pump(const Duration(milliseconds: 3999));
    await controller.refresh();
    expect(controller.info?.ip, '203.0.113.1');
    await tester.pump(const Duration(milliseconds: 1));
    await controller.refresh();
    expect(controller.info?.ip, '203.0.113.2');
    controller.dispose();
  });

  testWidgets('a slow request stays exclusive after cooldown expires', (
    tester,
  ) async {
    final pending = Completer<PublicIpInfo>();
    var calls = 0;
    final controller = PublicIpController(
      load: () {
        calls++;
        return calls == 1 ? pending.future : Future.value(_info('203.0.113.9'));
      },
    );
    final request = controller.refresh();
    await tester.pump(const Duration(seconds: 5));
    await controller.refresh();
    pending.complete(_info('203.0.113.8'));
    await request;
    expect(controller.info?.ip, '203.0.113.8');
    expect(controller.canRefresh, isTrue);
    controller.dispose();
  });

  testWidgets(
    'a failed refresh preserves the last successful address and flag',
    (tester) async {
      var calls = 0;
      final controller = PublicIpController(
        load: () async {
          if (++calls > 1) throw StateError('network unavailable');
          return _info('203.0.113.8');
        },
      );
      await controller.refresh();
      await tester.pump(const Duration(seconds: 4));
      await controller.refresh();
      expect(controller.info?.ip, '203.0.113.8');
      expect(controller.info?.countryCode, 'SE');
      expect(controller.failed, isTrue);
      expect(controller.loading, isFalse);
      controller.dispose();
    },
  );

  testWidgets('closing ignores late results without bypassing cooldown', (
    tester,
  ) async {
    final pending = Completer<PublicIpInfo>();
    final controller = PublicIpController(load: () => pending.future);
    final request = controller.refresh();
    controller.cancel();
    pending.complete(_info('203.0.113.8'));
    await request;
    expect(controller.info, isNull);
    expect(controller.loading, isFalse);
    expect(controller.canRefresh, isFalse);
    await tester.pump(const Duration(seconds: 4));
    expect(controller.canRefresh, isTrue);
    controller.dispose();
  });
}
