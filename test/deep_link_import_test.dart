import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/app/deep_link_import.dart';

void main() {
  group('DeepLinkImportRequest.fromPayload', () {
    test('keeps ordinary subscription urls unchanged', () {
      final request = DeepLinkImportRequest.fromPayload({
        'url': 'https://example.com/subscription',
        'name': ' Example ',
        'scheme': 'meowvpn',
      });

      expect(request, isNotNull);
      expect(request!.url, 'https://example.com/subscription');
      expect(request.name, 'Example');
      expect(request.scheme, 'meowvpn');
      expect(request.sourceType, DeepLinkImportSource.etonifyImport);
    });

    test('preserves an explicit Etonify import source type', () {
      final request = DeepLinkImportRequest.fromPayload({
        'url': 'https://example.com/subscription',
        'scheme': 'etonify',
        'sourceType': 'etonifyImport',
      });

      expect(request, isNotNull);
      expect(request!.url, 'https://example.com/subscription');
      expect(request.sourceType, DeepLinkImportSource.etonifyImport);
    });

    test('normalizes sing-box remote profile import links', () {
      final request = DeepLinkImportRequest.fromPayload({
        'url':
            'sing-box://import-remote-profile/?url=https://example.com/sub.json',
        'scheme': 'sing-box',
      });

      expect(request, isNotNull);
      expect(request!.url, 'https://example.com/sub.json');
      expect(request.sourceType, DeepLinkImportSource.singBoxRemoteProfile);
    });

    test('rejects Happ scheme links', () {
      expect(
        DeepLinkImportRequest.fromPayload({
          'url': 'happ://crypt5/encrypted-payload',
          'scheme': 'happ',
        }),
        isNull,
      );
    });

    test('rejects wrapped Happ links even if the URL is already resolved', () {
      expect(
        DeepLinkImportRequest.fromPayload({
          'url': 'https://example.com/subscription',
          'scheme': 'happ',
        }),
        isNull,
      );
      expect(
        DeepLinkImportRequest.fromPayload({
          'url': 'https://example.com/subscription',
          'sourceType': 'happAdd',
        }),
        isNull,
      );
    });

    test('rejects a missing or blank URL', () {
      expect(DeepLinkImportRequest.fromPayload({'url': '  '}), isNull);
      expect(DeepLinkImportRequest.fromPayload({'name': 'No URL'}), isNull);
    });
  });
}
