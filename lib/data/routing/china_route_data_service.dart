import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meow_client/core/network/vpn_aware_remote_download.dart';
import 'package:meow_client/core/platform/android_files_dir.dart';

const List<int> _srsMagicBytes = <int>[0x53, 0x52, 0x53];

@visibleForTesting
bool isChinaRouteRuleSetValidForTest(Uint8List bytes) =>
    _isUsableSrsBytes(bytes);

DateTime? parseChinaRouteVersionTimestamp(String value) {
  final match = RegExp(r'\d{12}').firstMatch(value.trim());
  if (match == null) return null;
  final digits = match.group(0)!;
  final year = int.parse(digits.substring(0, 4));
  final month = int.parse(digits.substring(4, 6));
  final day = int.parse(digits.substring(6, 8));
  final hour = int.parse(digits.substring(8, 10));
  final minute = int.parse(digits.substring(10, 12));
  final parsed = DateTime(year, month, day, hour, minute);
  if (parsed.year != year ||
      parsed.month != month ||
      parsed.day != day ||
      parsed.hour != hour ||
      parsed.minute != minute) {
    return null;
  }
  return parsed;
}

class ChinaRouteDataStatus {
  const ChinaRouteDataStatus({
    required this.available,
    required this.sourceName,
    required this.versionTag,
    this.sourceKind = ChinaRouteDataService.sourceKindLive,
    this.releaseTag,
    this.packageSha256,
    this.assetSizeBytes,
    this.verifiedAtMillis,
    this.verifiedFiles = const <String>[],
    this.chinaGeositePath,
    this.chinaGeoipPath,
    this.installedAtMillis,
    this.lastUpdateCheckAtMillis,
  });

  const ChinaRouteDataStatus.unavailable()
    : available = false,
      sourceName = ChinaRouteDataService.chinaRouteDataSourceName,
      versionTag = 'latest',
      sourceKind = ChinaRouteDataService.sourceKindLive,
      releaseTag = null,
      packageSha256 = null,
      assetSizeBytes = null,
      verifiedAtMillis = null,
      verifiedFiles = const <String>[],
      chinaGeositePath = null,
      chinaGeoipPath = null,
      installedAtMillis = null,
      lastUpdateCheckAtMillis = null;

  final bool available;
  final String sourceName;
  final String versionTag;
  final String sourceKind;
  final String? releaseTag;
  final String? packageSha256;
  final int? assetSizeBytes;
  final int? verifiedAtMillis;
  final List<String> verifiedFiles;
  final String? chinaGeositePath;
  final String? chinaGeoipPath;
  final int? installedAtMillis;
  final int? lastUpdateCheckAtMillis;

  bool get chinaRouteDataAvailable =>
      chinaGeositePath?.isNotEmpty == true &&
      chinaGeoipPath?.isNotEmpty == true;

  DateTime? get installedAt => installedAtMillis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(installedAtMillis!);

  DateTime? get verifiedAt => verifiedAtMillis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(verifiedAtMillis!);

  DateTime? get lastUpdateCheckAt => lastUpdateCheckAtMillis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastUpdateCheckAtMillis!);

  bool get needsDailyUpdate {
    final lastCheck = lastUpdateCheckAt ?? installedAt;
    return lastCheck == null ||
        DateTime.now().difference(lastCheck) >= const Duration(hours: 24);
  }
}

class ChinaRouteDataFile {
  const ChinaRouteDataFile({required this.name, required this.sizeBytes});

  final String name;
  final int sizeBytes;

  bool get isGeoIp => name.startsWith('geoip-');
}

enum ChinaRouteUpdateStage {
  checking,
  retryingWithoutVpn,
  downloadingRuleSets,
  verifyingRuleSets,
  activating,
  complete,
}

class ChinaRouteUpdateProgress {
  const ChinaRouteUpdateProgress({
    required this.stage,
    this.completedBytes = 0,
    this.totalBytes = 0,
    this.completedItems = 0,
    this.totalItems = 0,
    this.isRetryingWithoutVpn = false,
  });

  final ChinaRouteUpdateStage stage;
  final int completedBytes;
  final int totalBytes;
  final int completedItems;
  final int totalItems;
  final bool isRetryingWithoutVpn;

  double? get fraction {
    if (totalBytes > 0) {
      return (completedBytes / totalBytes).clamp(0, 1).toDouble();
    }
    if (totalItems > 0) {
      return (completedItems / totalItems).clamp(0, 1).toDouble();
    }
    return null;
  }

  ChinaRouteUpdateProgress copyWith({
    ChinaRouteUpdateStage? stage,
    int? completedBytes,
    int? totalBytes,
    int? completedItems,
    int? totalItems,
    bool? isRetryingWithoutVpn,
  }) {
    return ChinaRouteUpdateProgress(
      stage: stage ?? this.stage,
      completedBytes: completedBytes ?? this.completedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      completedItems: completedItems ?? this.completedItems,
      totalItems: totalItems ?? this.totalItems,
      isRetryingWithoutVpn: isRetryingWithoutVpn ?? this.isRetryingWithoutVpn,
    );
  }
}

abstract interface class ChinaRouteUpdateActivity {
  bool get isUpdating;
  ValueListenable<ChinaRouteUpdateProgress?> get progress;
}

class ChinaRouteDataService implements ChinaRouteUpdateActivity {
  ChinaRouteDataService._();

  static final ChinaRouteDataService instance = ChinaRouteDataService._();

  static const chinaRouteDataSourceName = 'aliothlab/rule-set';
  static const chinaRouteDataSourceUrl =
      'https://github.com/aliothlab/rule-set';
  static const sourceKindLive = 'live';
  static const _chinaGeositeUrl =
      'https://raw.githubusercontent.com/aliothlab/rule-set/main/rules/geosite-cn.srs';
  static const _chinaGeoipUrl =
      'https://raw.githubusercontent.com/aliothlab/rule-set/main/rules/geoip-cn.srs';
  static const _maxChinaRuleSetBytes = 4 * 1024 * 1024;

  Future<ChinaRouteDataStatus>? _updateInFlight;

  @override
  final ValueNotifier<ChinaRouteUpdateProgress?> progress = ValueNotifier(null);

  @override
  bool get isUpdating => _updateInFlight != null;

  void _emitProgress(
    ChinaRouteUpdateStage stage, {
    int completedBytes = 0,
    int totalBytes = 0,
    bool? isRetryingWithoutVpn,
  }) {
    final isDownloading =
        stage == ChinaRouteUpdateStage.downloadingRuleSets ||
        stage == ChinaRouteUpdateStage.checking;
    progress.value = ChinaRouteUpdateProgress(
      stage: stage,
      completedBytes: completedBytes,
      totalBytes: totalBytes,
      isRetryingWithoutVpn:
          isRetryingWithoutVpn ??
          (isDownloading
              ? progress.value?.isRetryingWithoutVpn ?? false
              : false),
    );
  }

  Future<ChinaRouteDataStatus> loadStatus() async {
    final paths = await _storagePaths();
    await _migrateLegacyChinaRuleSets(paths);
    final geositeFile = File(paths.chinaGeositePath);
    final geoipFile = File(paths.chinaGeoipPath);
    final available =
        await _hasUsableRuleSet(geositeFile) &&
        await _hasUsableRuleSet(geoipFile);
    if (!available) {
      return const ChinaRouteDataStatus.unavailable();
    }

    final geositeModified = await geositeFile.lastModified();
    final geoipModified = await geoipFile.lastModified();
    final latestModified = geositeModified.isAfter(geoipModified)
        ? geositeModified
        : geoipModified;
    final timestamp = latestModified.millisecondsSinceEpoch;
    final versionTag = _versionTag(latestModified);
    final geositeSize = await geositeFile.length();
    final geoipSize = await geoipFile.length();
    return ChinaRouteDataStatus(
      available: true,
      sourceName: chinaRouteDataSourceName,
      versionTag: versionTag,
      sourceKind: sourceKindLive,
      releaseTag: versionTag,
      assetSizeBytes: geositeSize + geoipSize,
      verifiedAtMillis: timestamp,
      verifiedFiles: const <String>['geosite-cn.srs', 'geoip-cn.srs'],
      chinaGeositePath: paths.chinaGeositePath,
      chinaGeoipPath: paths.chinaGeoipPath,
      installedAtMillis: timestamp,
      lastUpdateCheckAtMillis: timestamp,
    );
  }

  Future<List<ChinaRouteDataFile>> listInstalledFiles() async {
    final status = await loadStatus();
    if (!status.chinaRouteDataAvailable) {
      return const <ChinaRouteDataFile>[];
    }
    final files = <ChinaRouteDataFile>[];
    for (final entry in <(String, String)>[
      ('geosite-cn.srs', status.chinaGeositePath!),
      ('geoip-cn.srs', status.chinaGeoipPath!),
    ]) {
      final file = File(entry.$2);
      try {
        final stat = await file.stat();
        if (stat.type == FileSystemEntityType.file && stat.size > 4) {
          files.add(ChinaRouteDataFile(name: entry.$1, sizeBytes: stat.size));
        }
      } on FileSystemException {
        // An atomic update may replace a file between status and stat.
      }
    }
    return files;
  }

  Future<ChinaRouteDataStatus> ensureChinaRouteData({bool force = false}) {
    final inFlight = _updateInFlight;
    if (inFlight != null) return inFlight;
    final future = _ensureChinaRouteData(force: force);
    _updateInFlight = future;
    return future.whenComplete(() {
      if (identical(_updateInFlight, future)) {
        _updateInFlight = null;
        progress.value = null;
      }
    });
  }

  Future<ChinaRouteDataStatus> _ensureChinaRouteData({
    required bool force,
  }) async {
    _emitProgress(ChinaRouteUpdateStage.checking);
    final current = await loadStatus();
    if (!force &&
        current.chinaRouteDataAvailable &&
        !current.needsDailyUpdate) {
      _emitProgress(ChinaRouteUpdateStage.complete);
      return current;
    }

    final paths = await _storagePaths();
    await Directory(paths.ruleSetDirectoryPath).create(recursive: true);
    _emitProgress(ChinaRouteUpdateStage.downloadingRuleSets);
    final geositeBytes = await _downloadBytes(Uri.parse(_chinaGeositeUrl));
    final geoipBytes = await _downloadBytes(
      Uri.parse(_chinaGeoipUrl),
      completedBytesOffset: geositeBytes.length,
    );
    _emitProgress(
      ChinaRouteUpdateStage.verifyingRuleSets,
      completedBytes: geositeBytes.length + geoipBytes.length,
      totalBytes: geositeBytes.length + geoipBytes.length,
    );
    if (!_isUsableSrsBytes(geositeBytes) || !_isUsableSrsBytes(geoipBytes)) {
      throw const FormatException(
        'Downloaded China route data is not valid SRS',
      );
    }

    _emitProgress(ChinaRouteUpdateStage.activating);
    await _writeAtomically(paths.chinaGeositePath, geositeBytes);
    await _writeAtomically(paths.chinaGeoipPath, geoipBytes);
    _emitProgress(
      ChinaRouteUpdateStage.complete,
      completedBytes: geositeBytes.length + geoipBytes.length,
      totalBytes: geositeBytes.length + geoipBytes.length,
    );
    return loadStatus();
  }

  Future<ChinaRouteDataStatus> deleteInstalled() async {
    final paths = await _storagePaths();
    for (final directoryPath in <String>[
      paths.baseDirectoryPath,
      paths.legacyDirectoryPath,
    ]) {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        try {
          await directory.delete(recursive: true);
        } on FileSystemException {
          // Removing cached route data is best-effort.
        }
      }
    }
    return const ChinaRouteDataStatus.unavailable();
  }

  Future<Uint8List> _downloadBytes(
    Uri uri, {
    int completedBytesOffset = 0,
  }) async {
    final result = await VpnAwareRemoteDownloader.instance.fetchBytes(
      uri: uri,
      maximumBytes: _maxChinaRuleSetBytes,
      headers: const <String, String>{
        'User-Agent': 'EtonifyRouteData/1',
        'Accept': 'application/octet-stream,*/*',
      },
      onRouteAttempt: (route, isFallback) {
        if (isFallback && route == RemoteDownloadRoute.underlying) {
          final current = progress.value;
          if (current != null) {
            progress.value = current.copyWith(isRetryingWithoutVpn: true);
          } else {
            _emitProgress(
              ChinaRouteUpdateStage.downloadingRuleSets,
              isRetryingWithoutVpn: true,
            );
          }
        }
      },
      onProgress: (completed, total) {
        _emitProgress(
          ChinaRouteUpdateStage.downloadingRuleSets,
          completedBytes: completedBytesOffset + completed,
          totalBytes: total > 0 ? completedBytesOffset + total : 0,
        );
      },
    );
    return result.bytes ?? Uint8List(0);
  }

  Future<void> _migrateLegacyChinaRuleSets(
    _ChinaRouteStoragePaths paths,
  ) async {
    final legacyRuleDirectory = Directory(paths.legacyRuleSetDirectoryPath);
    for (final entry in <(String, String)>[
      ('geosite-cn.srs', paths.chinaGeositePath),
      ('geoip-cn.srs', paths.chinaGeoipPath),
    ]) {
      final source = File('${legacyRuleDirectory.path}/${entry.$1}');
      final target = File(entry.$2);
      try {
        if (await target.exists() || !await _hasUsableRuleSet(source)) {
          continue;
        }
        final modifiedAt = await source.lastModified();
        await _writeAtomically(target.path, await source.readAsBytes());
        await target.setLastModified(modifiedAt);
      } on FileSystemException {
        // A partial or locked legacy file is left untouched for the next load.
      }
    }

    final legacyDirectory = Directory(paths.legacyDirectoryPath);
    if (await legacyDirectory.exists()) {
      try {
        await legacyDirectory.delete(recursive: true);
      } on FileSystemException {
        // Legacy Russia route assets are no longer used; cleanup is best-effort.
      }
    }
  }

  Future<_ChinaRouteStoragePaths> _storagePaths() async {
    final rootPath = Platform.isAndroid
        ? await AndroidFilesDir.ensureInitialized()
        : Directory.systemTemp.path;
    final routeDataDirectory = Directory('$rootPath/route-data');
    final baseDirectory = Directory(
      '${routeDataDirectory.path}/china-route-data',
    );
    final ruleSetDirectory = Directory('${baseDirectory.path}/rule-set');
    return _ChinaRouteStoragePaths(
      baseDirectoryPath: baseDirectory.path,
      ruleSetDirectoryPath: ruleSetDirectory.path,
      chinaGeositePath: '${ruleSetDirectory.path}/geosite-cn.srs',
      chinaGeoipPath: '${ruleSetDirectory.path}/geoip-cn.srs',
      legacyDirectoryPath: '${routeDataDirectory.path}/russia-v2ray-rules-dat',
      legacyRuleSetDirectoryPath:
          '${routeDataDirectory.path}/russia-v2ray-rules-dat/rule-set-china',
    );
  }

  Future<void> _writeAtomically(String path, List<int> bytes) async {
    final target = File(path);
    await target.parent.create(recursive: true);
    final temp = File('$path.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    try {
      await temp.rename(path);
      return;
    } on FileSystemException {
      final backup = File('$path.bak');
      if (await backup.exists()) {
        await backup.delete();
      }
      if (await target.exists()) {
        await target.rename(backup.path);
      }
      try {
        await temp.rename(path);
        if (await backup.exists()) {
          await backup.delete();
        }
      } catch (_) {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(path);
        }
        rethrow;
      }
    }
  }
}

class _ChinaRouteStoragePaths {
  const _ChinaRouteStoragePaths({
    required this.baseDirectoryPath,
    required this.ruleSetDirectoryPath,
    required this.chinaGeositePath,
    required this.chinaGeoipPath,
    required this.legacyDirectoryPath,
    required this.legacyRuleSetDirectoryPath,
  });

  final String baseDirectoryPath;
  final String ruleSetDirectoryPath;
  final String chinaGeositePath;
  final String chinaGeoipPath;
  final String legacyDirectoryPath;
  final String legacyRuleSetDirectoryPath;
}

bool _isUsableSrsBytes(Uint8List bytes) =>
    bytes.length > _srsMagicBytes.length &&
    bytes[0] == _srsMagicBytes[0] &&
    bytes[1] == _srsMagicBytes[1] &&
    bytes[2] == _srsMagicBytes[2];

Future<bool> _hasUsableRuleSet(File file) async {
  RandomAccessFile? reader;
  try {
    if (!await file.exists() || await file.length() <= _srsMagicBytes.length) {
      return false;
    }
    reader = await file.open();
    final magic = await reader.read(_srsMagicBytes.length);
    return magic.length == _srsMagicBytes.length &&
        magic[0] == _srsMagicBytes[0] &&
        magic[1] == _srsMagicBytes[1] &&
        magic[2] == _srsMagicBytes[2];
  } on FileSystemException {
    return false;
  } finally {
    await reader?.close();
  }
}

String _versionTag(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '${value.month.toString().padLeft(2, '0')}'
    '${value.day.toString().padLeft(2, '0')}'
    '${value.hour.toString().padLeft(2, '0')}'
    '${value.minute.toString().padLeft(2, '0')}';
