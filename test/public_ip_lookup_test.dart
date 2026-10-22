import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/public_ip_controller.dart';
import 'package:meow_client/singbox/singbox_api.g.dart';

PublicIpLookupResponseMessage _response({
  required PublicIpLookupRequestMessage request,
  String? outbound,
  int? network,
  String plan = 'plan-1',
  String core = 'core-1',
}) => PublicIpLookupResponseMessage(
  json: jsonEncode({
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
  }),
  planId: plan,
  coreGeneration: core,
  networkGeneration: network ?? request.networkGeneration,
  outboundTag: outbound ?? request.outboundTag,
);

void main() {
  testWidgets('whole app deadline cancels only the pending core request', (
    tester,
  ) async {
    final pending = Completer<PublicIpLookupResponseMessage>();
    String? requestId;
    String? cancelledId;
    final lookup = PublicIpLookup(
      lookup: (request) {
        requestId = request.requestId;
        return pending.future;
      },
      cancel: (id) async {
        cancelledId = id;
      },
    );
    final operation = lookup.load(outboundTag: 'leaf-a');
    final assertion = expectLater(operation, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 10));
    await assertion;
    expect(cancelledId, requestId);
  });

  test(
    'uses exactly the requested provider, outbound and network identity',
    () async {
      PublicIpLookupRequestMessage? sent;
      final lookup = PublicIpLookup(
        lookup: (request) async {
          sent = request;
          return _response(request: request);
        },
      );
      final result = await lookup.load(
        source: PublicIpSource.ipQuery,
        outboundTag: 'leaf-a',
        networkGeneration: 7,
      );
      expect(sent!.provider, 'ipQuery');
      expect(sent!.outboundTag, 'leaf-a');
      expect(sent!.networkGeneration, 7);
      expect(sent!.timeoutMillis, 10000);
      expect(result.ip, '203.0.113.8');
      expect(result.countryCode, 'SE');
      expect(result.identity!.planId, 'plan-1');
      expect(result.identity!.coreGeneration, 'core-1');
      expect(result.identity!.source, PublicIpSource.ipQuery);
      expect(result.identity!.outboundTag, 'leaf-a');
      expect(result.identity!.networkGeneration, 7);
    },
  );

  test('fails closed if selected outbound is unavailable', () async {
    final lookup = PublicIpLookup(
      lookup: (_) async => throw StateError('should not run'),
    );
    await expectLater(lookup.load(), throwsStateError);
  });

  test('rejects stale or incomplete response identity', () async {
    final lookup = PublicIpLookup(
      lookup: (request) async => _response(request: request, outbound: 'other'),
    );
    await expectLater(
      lookup.load(outboundTag: 'leaf-a', networkGeneration: 7),
      throwsStateError,
    );
    final incomplete = PublicIpLookup(
      lookup: (request) async =>
          _response(request: request, plan: '', core: ''),
    );
    await expectLater(
      incomplete.load(outboundTag: 'leaf-a', networkGeneration: 7),
      throwsStateError,
    );
  });

  test('cancel sends one matching request id and drops late result', () async {
    String? cancelled;
    final pending = Completer<PublicIpLookupResponseMessage>();
    final lookup = PublicIpLookup(
      lookup: (_) => pending.future,
      cancel: (id) async {
        cancelled = id;
      },
    );
    final operation = lookup.load(outboundTag: 'leaf-a', networkGeneration: 7);
    lookup.cancel();
    expect(cancelled, isNotNull);
    pending.complete(
      _response(
        request: PublicIpLookupRequestMessage(
          requestId: cancelled!,
          outboundTag: 'leaf-a',
          provider: 'ipQuery',
          networkGeneration: 7,
          timeoutMillis: 10000,
        ),
      ),
    );
    await expectLater(operation, throwsStateError);
  });

  test(
    'core error never changes provider or falls back to another request',
    () async {
      final sent = <String>[];
      final lookup = PublicIpLookup(
        lookup: (request) async {
          sent.add(request.provider);
          throw StateError('unsupported fixed DNS dependency');
        },
      );
      await expectLater(
        lookup.load(source: PublicIpSource.ipWho, outboundTag: 'leaf-a'),
        throwsStateError,
      );
      expect(sent, ['ipWho']);
    },
  );
}
