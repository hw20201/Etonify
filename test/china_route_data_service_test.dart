import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/data/routing/china_route_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates China SRS files and removes legacy Russia route cache',
    () async {
      await _withIsolatedRouteStorage(() async {
        final legacyDirectory = Directory(
          '${Directory.systemTemp.path}/route-data/russia-v2ray-rules-dat',
        );
        final legacyRuleDirectory = Directory(
          '${legacyDirectory.path}/rule-set-china',
        );
        await legacyRuleDirectory.create(recursive: true);
        final modifiedAt = DateTime(2026, 10, 14, 10, 30);
        for (final fileName in <String>['geosite-cn.srs', 'geoip-cn.srs']) {
          final file = File('${legacyRuleDirectory.path}/$fileName');
          await file.writeAsBytes(_validSrsBytes);
          await file.setLastModified(modifiedAt);
        }
        final oldRussiaRule = File(
          '${legacyDirectory.path}/rule-set-geosite/geosite-ru-blocked.srs',
        );
        await oldRussiaRule.parent.create(recursive: true);
        await oldRussiaRule.writeAsBytes(_validSrsBytes);
        final oldCommunityList = File(
          '${legacyDirectory.path}/domain-list-community/category-gov-ru.txt',
        );
        await oldCommunityList.parent.create(recursive: true);
        await oldCommunityList.writeAsString('example.ru\n');

        final status = await ChinaRouteDataService.instance.loadStatus();

        expect(status.available, isTrue);
        expect(status.chinaRouteDataAvailable, isTrue);
        expect(
          status.sourceName,
          ChinaRouteDataService.chinaRouteDataSourceName,
        );
        expect(status.sourceKind, ChinaRouteDataService.sourceKindLive);
        expect(status.chinaGeositePath, contains('china-route-data/rule-set'));
        expect(status.chinaGeoipPath, contains('china-route-data/rule-set'));
        expect(status.verifiedFiles, ['geosite-cn.srs', 'geoip-cn.srs']);
        expect(File(status.chinaGeositePath!).lastModifiedSync(), modifiedAt);
        expect(await legacyDirectory.exists(), isFalse);

        final installedFiles = await ChinaRouteDataService.instance
            .listInstalledFiles();
        expect(installedFiles.map((file) => file.name), [
          'geosite-cn.srs',
          'geoip-cn.srs',
        ]);
      });
    },
  );

  test('rejects missing or corrupt China rule sets', () async {
    await _withIsolatedRouteStorage(() async {
      final directory = Directory(
        '${Directory.systemTemp.path}/route-data/china-route-data/rule-set',
      );
      await directory.create(recursive: true);
      await File(
        '${directory.path}/geosite-cn.srs',
      ).writeAsBytes(_validSrsBytes);
      await File(
        '${directory.path}/geoip-cn.srs',
      ).writeAsBytes(_corruptSrsBytes());

      final status = await ChinaRouteDataService.instance.loadStatus();

      expect(status.available, isFalse);
      expect(status.chinaRouteDataAvailable, isFalse);
      expect(
        ChinaRouteDataService.instance.listInstalledFiles(),
        completion(isEmpty),
      );
    });
  });

  test('fresh China SRS data does not trigger a network download', () async {
    await _withIsolatedRouteStorage(() async {
      final directory = Directory(
        '${Directory.systemTemp.path}/route-data/china-route-data/rule-set',
      );
      await directory.create(recursive: true);
      for (final fileName in <String>['geosite-cn.srs', 'geoip-cn.srs']) {
        await File('${directory.path}/$fileName').writeAsBytes(_validSrsBytes);
      }

      final status = await ChinaRouteDataService.instance
          .ensureChinaRouteData();

      expect(status.chinaRouteDataAvailable, isTrue);
      expect(ChinaRouteDataService.instance.isUpdating, isFalse);
      expect(ChinaRouteDataService.instance.progress.value, isNull);
    });
  });

  test(
    'downloads both China rule sets from the SagerNet jsDelivr sources',
    () async {
      await _withIsolatedRouteStorage(() async {
        final requested = <Uri>[];
        final service = ChinaRouteDataService.forTesting(
          downloadBytes: (uri) async {
            requested.add(uri);
            return Uint8List.fromList(_validSrsBytes);
          },
        );

        final status = await service.ensureChinaRouteData(force: true);

        expect(requested, [
          Uri.parse(
            'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-cn.srs',
          ),
          Uri.parse(
            'https://cdn.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-cn.srs',
          ),
        ]);
        expect(status.sourceName, 'SagerNet/sing-geosite + sing-geoip');
        expect(status.chinaRouteDataAvailable, isTrue);
      });
    },
  );

  test('falls back to aliothlab when primary SRS validation fails', () async {
    await _withIsolatedRouteStorage(() async {
      final requested = <Uri>[];
      final service = ChinaRouteDataService.forTesting(
        downloadBytes: (uri) async {
          requested.add(uri);
          return uri.host == 'cdn.jsdelivr.net'
              ? _corruptSrsBytes()
              : Uint8List.fromList(_validSrsBytes);
        },
      );

      final status = await service.ensureChinaRouteData(force: true);

      expect(requested, [
        Uri.parse(
          'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-cn.srs',
        ),
        Uri.parse(
          'https://cdn.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-cn.srs',
        ),
        Uri.parse(
          'https://raw.githubusercontent.com/aliothlab/rule-set/main/rules/geosite-cn.srs',
        ),
        Uri.parse(
          'https://raw.githubusercontent.com/aliothlab/rule-set/main/rules/geoip-cn.srs',
        ),
      ]);
      expect(status.chinaRouteDataAvailable, isTrue);
      expect(File(status.chinaGeositePath!).readAsBytesSync(), _validSrsBytes);
    });
  });

  test(
    'falls back to aliothlab when the primary source cannot be downloaded',
    () async {
      await _withIsolatedRouteStorage(() async {
        final requested = <Uri>[];
        final service = ChinaRouteDataService.forTesting(
          downloadBytes: (uri) async {
            requested.add(uri);
            if (uri.host == 'cdn.jsdelivr.net') {
              throw const SocketException('primary unavailable');
            }
            return Uint8List.fromList(_validSrsBytes);
          },
        );

        final status = await service.ensureChinaRouteData(force: true);

        expect(requested, [
          Uri.parse(
            'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-cn.srs',
          ),
          Uri.parse(
            'https://raw.githubusercontent.com/aliothlab/rule-set/main/rules/geosite-cn.srs',
          ),
          Uri.parse(
            'https://raw.githubusercontent.com/aliothlab/rule-set/main/rules/geoip-cn.srs',
          ),
        ]);
        expect(status.chinaRouteDataAvailable, isTrue);
      });
    },
  );

  test('status becomes due for refresh after 24 hours', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fresh = ChinaRouteDataStatus(
      available: true,
      sourceName: ChinaRouteDataService.chinaRouteDataSourceName,
      versionTag: '202610152000',
      lastUpdateCheckAtMillis: now,
    );
    final stale = ChinaRouteDataStatus(
      available: true,
      sourceName: ChinaRouteDataService.chinaRouteDataSourceName,
      versionTag: '202610141900',
      lastUpdateCheckAtMillis: DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch,
    );

    expect(fresh.needsDailyUpdate, isFalse);
    expect(stale.needsDailyUpdate, isTrue);
    expect(const ChinaRouteDataStatus.unavailable().needsDailyUpdate, isTrue);
  });

  test(
    'version parser accepts valid timestamps and rejects invalid values',
    () {
      expect(
        parseChinaRouteVersionTimestamp('202610141030'),
        DateTime(2026, 10, 14, 10, 30),
      );
      expect(parseChinaRouteVersionTimestamp('latest'), isNull);
      expect(parseChinaRouteVersionTimestamp('202613401280'), isNull);
    },
  );

  test('SRS validation checks version and complete bounded zlib payload', () {
    expect(isChinaRouteRuleSetValidForTest(_validSrsBytes), isTrue);
    expect(
      isChinaRouteRuleSetValidForTest(Uint8List.fromList([0x53, 0x52, 0x53])),
      isFalse,
    );
    expect(isChinaRouteRuleSetValidForTest(_corruptSrsBytes()), isFalse);
    expect(
      isChinaRouteRuleSetValidForTest(
        Uint8List.fromList(
          _validSrsBytes.sublist(0, _validSrsBytes.length - 3),
        ),
      ),
      isFalse,
    );
    expect(isChinaRouteRuleSetValidForTest(_buildSrsBytes(<int>[0])), isFalse);
    final unsupportedVersion = Uint8List.fromList(_validSrsBytes)..[3] = 6;
    expect(isChinaRouteRuleSetValidForTest(unsupportedVersion), isFalse);
    final oversized = Uint8List(4 * 1024 * 1024 + 1)
      ..setRange(0, 4, <int>[0x53, 0x52, 0x53, 0x01]);
    expect(isChinaRouteRuleSetValidForTest(oversized), isFalse);
  });

  test('update progress remains bounded for byte counts', () {
    expect(
      const ChinaRouteUpdateProgress(
        stage: ChinaRouteUpdateStage.downloadingRuleSets,
        completedBytes: 25,
        totalBytes: 100,
      ).fraction,
      0.25,
    );
    expect(
      const ChinaRouteUpdateProgress(
        stage: ChinaRouteUpdateStage.verifyingRuleSets,
        completedBytes: 120,
        totalBytes: 100,
      ).fraction,
      1,
    );
    expect(
      const ChinaRouteUpdateProgress(
        stage: ChinaRouteUpdateStage.checking,
      ).fraction,
      isNull,
    );
    const initial = ChinaRouteUpdateProgress(
      stage: ChinaRouteUpdateStage.downloadingRuleSets,
      completedBytes: 10,
      totalBytes: 50,
    );
    final retrying = initial.copyWith(isRetryingWithoutVpn: true);
    expect(retrying.isRetryingWithoutVpn, isTrue);
    expect(retrying.completedBytes, 10);
    expect(retrying.totalBytes, 50);
  });
}

Uint8List _buildSrsBytes(List<int> uncompressedBody) => Uint8List.fromList(
  <int>[0x53, 0x52, 0x53, 0x01, ...ZLibEncoder().convert(uncompressedBody)],
);

final Uint8List _validSrsBytes = _buildSrsBytes(<int>[0x01, 0x00, 0xff]);

Uint8List _corruptSrsBytes() {
  final bytes = Uint8List.fromList(_validSrsBytes);
  bytes[bytes.length - 1] = bytes.last ^ 0xff;
  return bytes;
}

Future<T> _withIsolatedRouteStorage<T>(Future<T> Function() action) async {
  final root = await Directory.systemTemp.createTemp('etonify-route-test-');
  try {
    return await IOOverrides.runZoned(
      action,
      getSystemTempDirectory: () => root,
    );
  } finally {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  }
}
