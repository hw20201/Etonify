import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';

Map<String, Object?> _ipQueryResponse() => {
  'ip': '203.0.113.8',
  'isp': {
    'asn': 'AS64500',
    'org': 'Example Organization',
    'isp': 'Example Network',
  },
  'location': {
    'country': 'Sweden',
    'country_code': 'se',
    'city': 'Stockholm',
    'state': 'Stockholm County',
  },
};

void main() {
  test(
    'ipquery.io is queried over HTTPS and parses location information',
    () async {
      var requests = 0;
      final lookup = PublicIpLookup(
        clientFactory: () => MockClient((request) async {
          requests++;
          expect(request.followRedirects, isFalse);
          expect(request.headers['Cache-Control'], 'no-cache');
          expect(request.headers.containsKey('Authorization'), isFalse);
          if (request.url.path == '/') {
            expect(request.url.toString(), 'https://api.ipquery.io/');
            expect(request.headers['Accept'], 'text/plain');
            return http.Response('203.0.113.8\n', 200);
          }
          expect(request.url.scheme, 'https');
          expect(request.url.host, 'api.ipquery.io');
          expect(request.url.path, '/203.0.113.8');
          expect(request.url.queryParameters['format'], 'json');
          expect(request.headers['Accept'], 'application/json');
          return http.Response(jsonEncode(_ipQueryResponse()), 200);
        }),
      );

      final info = await lookup.load();
      expect(requests, 2);
      expect(info.ip, '203.0.113.8');
      expect(info.countryCode, 'SE');
      expect(info.country, 'Sweden');
      expect(info.region, 'Stockholm County');
      expect(info.city, 'Stockholm');
      expect(info.organization, 'Example Organization');
      expect(info.asn, 'AS64500');
      expect(info.isp, 'Example Network');
      expect(info.source, PublicIpSource.ipQuery);
      lookup.cancel();
    },
  );

  test('ip-api choice calls only its HTTP geolocation endpoint', () async {
    var requests = 0;
    final lookup = PublicIpLookup(
      clientFactory: () => MockClient((request) async {
        requests++;
        expect(request.url.scheme, 'http');
        expect(request.url.host, 'ip-api.com');
        expect(request.url.path, '/json/');
        expect(request.url.queryParameters['fields'], contains('countryCode'));
        expect(request.url.queryParameters['fields'], isNot(contains('proxy')));
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          jsonEncode({
            'status': 'success',
            'query': '2001:db8::8',
            'country': 'Germany',
            'countryCode': 'DE',
            'regionName': 'Berlin',
            'city': 'Berlin',
            'isp': 'Example ISP',
            'org': 'Example Hosting GmbH',
            'as': 'AS64501 Example Hosting GmbH',
          }),
          200,
        );
      }),
    );

    final info = await lookup.load(source: PublicIpSource.ipApi);
    expect(requests, 1);
    expect(info.ip, '2001:db8::8');
    expect(info.countryCode, 'DE');
    expect(info.country, 'Germany');
    expect(info.city, 'Berlin');
    expect(info.organization, 'Example Hosting GmbH');
    expect(info.asn, 'AS64501');
    expect(info.source, PublicIpSource.ipApi);
    lookup.cancel();
  });

  test('ipwho.is choice uses HTTPS and extracts country and ASN', () async {
    var requests = 0;
    final lookup = PublicIpLookup(
      clientFactory: () => MockClient((request) async {
        requests++;
        expect(request.url.toString(), 'https://ipwho.is/');
        expect(request.url.scheme, 'https');
        return http.Response(
          jsonEncode({
            'success': true,
            'ip': '198.51.100.7',
            'country': 'Japan',
            'country_code': 'JP',
            'region': 'Tokyo',
            'city': 'Tokyo',
            'connection': {
              'asn': 64502,
              'org': 'Example KK',
              'isp': 'Example ISP',
            },
          }),
          200,
        );
      }),
    );

    final info = await lookup.load(source: PublicIpSource.ipWho);
    expect(requests, 1);
    expect(info.ip, '198.51.100.7');
    expect(info.countryCode, 'JP');
    expect(info.country, 'Japan');
    expect(info.city, 'Tokyo');
    expect(info.asn, 'AS64502');
    expect(info.source, PublicIpSource.ipWho);
    lookup.cancel();
  });

  test(
    'a failed chosen provider is not silently replaced by another site',
    () async {
      var requests = 0;
      final lookup = PublicIpLookup(
        clientFactory: () => MockClient((request) async {
          requests++;
          expect(request.url.host, 'api.ipquery.io');
          return http.Response('unavailable', 503);
        }),
      );

      await expectLater(lookup.load(), throwsA(isA<HttpException>()));
      expect(requests, 1);
      lookup.cancel();
    },
  );

  test(
    'ip-api rate limit response prevents immediate repeated requests',
    () async {
      var requests = 0;
      final lookup = PublicIpLookup(
        clientFactory: () => MockClient((request) async {
          requests++;
          return http.Response(
            'rate limited',
            429,
            headers: const {'x-rl': '0', 'x-ttl': '60'},
          );
        }),
      );

      await expectLater(
        lookup.load(source: PublicIpSource.ipApi),
        throwsA(isA<HttpException>()),
      );
      await expectLater(
        lookup.load(source: PublicIpSource.ipApi),
        throwsA(isA<HttpException>()),
      );
      expect(requests, 1);
      lookup.cancel();
    },
  );

  test('invalid public IP text is rejected before a details request', () async {
    var requests = 0;
    final lookup = PublicIpLookup(
      clientFactory: () => MockClient((request) async {
        requests++;
        return http.Response('not-an-ip', 200);
      }),
    );

    await expectLater(lookup.load(), throwsFormatException);
    expect(requests, 1);
    lookup.cancel();
  });
}
