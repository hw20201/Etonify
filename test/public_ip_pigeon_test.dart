import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/singbox/singbox_api.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Pigeon preserves request identity, string core generation and cancel ID',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final lookupChannel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.meow_client.SingboxHostApi.lookupPublicIp',
        SingboxHostApi.pigeonChannelCodec,
      );
      final cancelChannel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.meow_client.SingboxHostApi.cancelPublicIp',
        SingboxHostApi.pigeonChannelCodec,
      );
      String? lookupId;
      String? cancelId;
      messenger.setMockDecodedMessageHandler<Object?>(lookupChannel, (
        message,
      ) async {
        final request =
            (message! as List<Object?>).single! as PublicIpLookupRequestMessage;
        lookupId = request.requestId;
        expect(request.outboundTag, 'proxy');
        expect(request.provider, 'ipQuery');
        expect(request.networkGeneration, 7);
        expect(request.timeoutMillis, 3000);
        return [
          PublicIpLookupResponseMessage(
            json: '{"ip":"203.0.113.1"}',
            planId: 'audit-plan',
            coreGeneration: 'core-uuid',
            networkGeneration: 7,
            outboundTag: 'proxy',
          ),
        ];
      });
      messenger.setMockDecodedMessageHandler<Object?>(cancelChannel, (
        message,
      ) async {
        cancelId = (message! as List<Object?>).single! as String;
        return [null];
      });
      addTearDown(() {
        messenger.setMockDecodedMessageHandler<Object?>(lookupChannel, null);
        messenger.setMockDecodedMessageHandler<Object?>(cancelChannel, null);
      });
      final api = SingboxHostApi();
      final response = await api.lookupPublicIp(
        PublicIpLookupRequestMessage(
          requestId: 'request-7',
          outboundTag: 'proxy',
          provider: 'ipQuery',
          networkGeneration: 7,
          timeoutMillis: 3000,
        ),
      );
      expect(response.coreGeneration, 'core-uuid');
      expect(response.planId, 'audit-plan');
      await api.cancelPublicIp('request-7');
      expect(cancelId, lookupId);
    },
  );
}
