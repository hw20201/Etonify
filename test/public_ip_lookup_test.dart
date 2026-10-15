import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';

Map<String, Object?> _ipQueryResponse({
  String ip = '203.0.113.8',
  int riskScore = 4,
}) => {
  'ip': ip,
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
  'risk': {
    'risk_score': riskScore,
    'is_mobile': false,
    'is_vpn': false,
    'is_tor': false,
    'is_proxy': false,
    'is_datacenter': true,
  },
};

Map<String, Object?> _ipApiResponse({String ip = '2001:db8::8'}) => {
  'status': 'success',
  'query': ip,
  'country': 'Germany',
  'countryCode': 'DE',
  'regionName': 'Berlin',
  'city': 'Berlin',
  'isp': 'Example ISP',
  'org': 'Example Hosting GmbH',
  'as': 'AS64501 Example Hosting GmbH',
  'mobile': false,
  'proxy': false,
  'hosting': true,
};

void main() {
  test(
    'queries ipquery.io over HTTPS and parses full intelligence details',
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
      expect(info.city, 'Stockholm');
      expect(info.organization, 'Example Organization');
      expect(info.asn, 'AS64500');
      expect(info.isp, 'Example Network');
      expect(info.riskScore, 4);
      expect(info.isDatacenter, isTrue);
      expect(info.networkType, PublicIpNetworkType.datacenter);
      expect(info.source, PublicIpSource.ipQuery);
      lookup.cancel();
    },
  );

  test(
    'falls back to ip-api.com after primary HTTP or parse failure',
    () async {
      for (final primaryFailure in [
        http.Response('unavailable', 503),
        http.Response('not-json', 200),
      ]) {
        var fallbackCalls = 0;
        final lookup = PublicIpLookup(
          clientFactory: () => MockClient((request) async {
            if (request.url.host == 'api.ipquery.io' &&
                request.url.path == '/') {
              return http.Response('203.0.113.8', 200);
            }
            if (request.url.host == 'api.ipquery.io') return primaryFailure;
            fallbackCalls++;
            expect(request.url.scheme, 'http');
            expect(request.url.host, 'ip-api.com');
            expect(request.url.path, '/json/');
            expect(
              request.url.queryParameters['fields'],
              contains('countryCode'),
            );
            expect(request.headers['Accept'], 'application/json');
            return http.Response(jsonEncode(_ipApiResponse()), 200);
          }),
        );

        final info = await lookup.load();
        expect(fallbackCalls, 1);
        expect(info.ip, '2001:db8::8');
        expect(info.countryCode, 'DE');
        expect(info.organization, 'Example Hosting GmbH');
        expect(info.asn, 'AS64501');
        expect(info.isDatacenter, isTrue);
        expect(info.source, PublicIpSource.ipApi);
        lookup.cancel();
      }
    },
  );

  test(
    'rejects invalid public IP data and unsuccessful backup responses',
    () async {
      final lookup = PublicIpLookup(
        clientFactory: () => MockClient((request) async {
          if (request.url.host == 'api.ipquery.io' && request.url.path == '/') {
            return http.Response('not-an-ip', 200);
          }
          return http.Response(
            jsonEncode({'status': 'fail', 'message': 'invalid query'}),
            200,
          );
        }),
      );

      await expectLater(lookup.load(), throwsFormatException);
      lookup.cancel();
    },
  );

  test(
    'an oversized primary response is rejected and uses the backup',
    () async {
      var fallbackCalls = 0;
      final lookup = PublicIpLookup(
        clientFactory: () => MockClient.streaming((request, body) async {
          if (request.url.host == 'api.ipquery.io' && request.url.path == '/') {
            return http.StreamedResponse(
              Stream.value(utf8.encode('203.0.113.8')),
              200,
            );
          }
          if (request.url.host == 'api.ipquery.io') {
            return http.StreamedResponse(
              Stream.fromIterable([
                utf8.encode('{"ip":"203.0.113.8"}'),
                List<int>.filled(16 * 1024, 65),
              ]),
              200,
            );
          }
          fallbackCalls++;
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(_ipApiResponse()))),
            200,
          );
        }),
      );

      final info = await lookup.load();
      expect(fallbackCalls, 1);
      expect(info.source, PublicIpSource.ipApi);
      expect(info.ip, '2001:db8::8');
      lookup.cancel();
    },
  );

  testWidgets('cancelling a stalled primary request skips the fallback', (
    tester,
  ) async {
    final stalled = Completer<http.Response>();
    var requests = 0;
    final lookup = PublicIpLookup(
      clientFactory: () => MockClient((request) {
        requests++;
        return stalled.future;
      }),
    );
    final request = lookup.load();
    final error = expectLater(request, throwsStateError);
    await tester.pump();
    lookup.cancel();
    await tester.pump(const Duration(seconds: 3));
    await error;
    expect(requests, 1);
    stalled.complete(http.Response('203.0.113.8', 200));
    await tester.pump();
  });

  testWidgets(
    'a stalled primary and backup are each bounded to three seconds',
    (tester) async {
      final stalled = Completer<http.Response>();
      var requests = 0;
      final lookup = PublicIpLookup(
        clientFactory: () => MockClient((request) {
          requests++;
          return stalled.future;
        }),
      );
      final error = expectLater(
        lookup.load(),
        throwsA(isA<TimeoutException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(requests, 2);
      await tester.pump(const Duration(seconds: 3));
      await error;
      expect(requests, 2);
      stalled.complete(http.Response('203.0.113.8', 200));
      await tester.pump();
    },
  );

  test(
    'honors ip-api.com X-Rl and X-Ttl before trying the backup again',
    () async {
      var primaryCalls = 0;
      var fallbackCalls = 0;
      final lookup = PublicIpLookup(
        clientFactory: () => MockClient((request) async {
          if (request.url.host == 'api.ipquery.io') {
            primaryCalls++;
            return http.Response('temporary failure', 503);
          }
          fallbackCalls++;
          return http.Response(
            jsonEncode(_ipApiResponse()),
            200,
            headers: const {'x-rl': '0', 'x-ttl': '60'},
          );
        }),
      );

      final first = await lookup.load();
      expect(first.source, PublicIpSource.ipApi);
      await expectLater(lookup.load(), throwsA(isA<HttpException>()));
      expect(primaryCalls, 2);
      expect(fallbackCalls, 1);
      lookup.cancel();
    },
  );
}
