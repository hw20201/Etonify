import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/data/routing/google_play_rule_set_data_service.dart';
import 'package:meow_client/data/routing/google_play_routing_preset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'downloads, validates and caches both SagerNet geosite SRS files',
    () async {
      final storage = await Directory.systemTemp.createTemp(
        'google-play-geosite-cache-',
      );
      final requested = <Uri>[];
      final service = GooglePlayRuleSetDataService.forTesting(
        storageRootPath: storage.path,
        downloadBytes: (uri) async {
          requested.add(uri);
          return _validSrsBytes;
        },
      );
      try {
        final status = await service.ensureRuleSets(force: true);

        expect(requested, [
          Uri.parse(googlePlayGeositeUrl),
          Uri.parse(googleCnGeositeUrl),
        ]);
        expect(status.available, isTrue);
        expect(File(status.geositeGooglePlayPath!).existsSync(), isTrue);
        expect(File(status.geositeGoogleCnPath!).existsSync(), isTrue);
        final loaded = await service.loadStatus();
        expect(loaded.available, isTrue);
        expect(loaded.geositeGooglePlayPath, status.geositeGooglePlayPath);
        expect(loaded.geositeGoogleCnPath, status.geositeGoogleCnPath);
      } finally {
        await storage.delete(recursive: true);
      }
    },
  );

  test('preserves validated cache when a dynamic refresh fails', () async {
    final storage = await Directory.systemTemp.createTemp(
      'google-play-geosite-refresh-',
    );
    var failDownload = false;
    final service = GooglePlayRuleSetDataService.forTesting(
      storageRootPath: storage.path,
      downloadBytes: (uri) async {
        if (failDownload) throw const HttpException('offline');
        return _validSrsBytes;
      },
    );
    try {
      final installed = await service.ensureRuleSets(force: true);
      expect(installed.available, isTrue);
      final previousBytes = await File(
        installed.geositeGooglePlayPath!,
      ).readAsBytes();

      failDownload = true;
      final refreshed = await service.ensureRuleSets(force: true);

      expect(refreshed.available, isTrue);
      expect(refreshed.geositeGooglePlayPath, installed.geositeGooglePlayPath);
      expect(
        await File(refreshed.geositeGooglePlayPath!).readAsBytes(),
        previousBytes,
      );
    } finally {
      await storage.delete(recursive: true);
    }
  });

  test(
    'rejects an invalid SRS response without installing a partial pair',
    () async {
      final storage = await Directory.systemTemp.createTemp(
        'google-play-geosite-invalid-',
      );
      final service = GooglePlayRuleSetDataService.forTesting(
        storageRootPath: storage.path,
        downloadBytes: (uri) async => uri.path.endsWith('google@cn.srs')
            ? Uint8List.fromList(<int>[0, 1, 2, 3, 4])
            : _validSrsBytes,
      );
      try {
        final status = await service.ensureRuleSets(force: true);

        expect(status.available, isFalse);
        expect(
          Directory(
            '${storage.path}/route-data/google-play-rule-data',
          ).existsSync(),
          isFalse,
        );
      } finally {
        await storage.delete(recursive: true);
      }
    },
  );
}

final Uint8List _validSrsBytes = Uint8List.fromList(<int>[
  0x53,
  0x52,
  0x53,
  2,
  ...ZLibCodec().encode(<int>[1, 0]),
]);
