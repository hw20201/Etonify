import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meow_client/core/network/vpn_aware_remote_download.dart';
import 'package:meow_client/core/platform/android_files_dir.dart';
import 'package:meow_client/data/routing/china_route_data_service.dart';
import 'package:meow_client/data/routing/google_play_routing_preset.dart';
import 'package:meow_client/logging/app_log_store.dart';

typedef GooglePlayRuleSetByteDownloader = Future<Uint8List> Function(Uri uri);

class GooglePlayRuleSetStatus {
  const GooglePlayRuleSetStatus({
    required this.available,
    this.geositeGooglePlayPath,
    this.geositeGoogleCnPath,
    this.lastUpdatedMillis,
  });

  const GooglePlayRuleSetStatus.unavailable()
    : available = false,
      geositeGooglePlayPath = null,
      geositeGoogleCnPath = null,
      lastUpdatedMillis = null;

  final bool available;
  final String? geositeGooglePlayPath;
  final String? geositeGoogleCnPath;
  final int? lastUpdatedMillis;

  bool get needsDailyUpdate {
    final lastUpdated = lastUpdatedMillis;
    return lastUpdated == null ||
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(lastUpdated),
            ) >=
            const Duration(hours: 24);
  }
}

/// Downloads and caches SagerNet Play geosites without bundling them in the
/// APK. A failed refresh preserves a validated cache; with no cache, callers
/// can still use the preset's explicit app-package and domain rules.
class GooglePlayRuleSetDataService {
  GooglePlayRuleSetDataService._({
    GooglePlayRuleSetByteDownloader? downloadOverride,
    String? storageRootOverride,
  }) : _downloadOverride = downloadOverride,
       _storageRootOverride = storageRootOverride;

  @visibleForTesting
  GooglePlayRuleSetDataService.forTesting({
    required GooglePlayRuleSetByteDownloader downloadBytes,
    required String storageRootPath,
  }) : this._(
         downloadOverride: downloadBytes,
         storageRootOverride: storageRootPath,
       );

  static final GooglePlayRuleSetDataService instance =
      GooglePlayRuleSetDataService._();

  static const sourceName = 'SagerNet/sing-geosite';
  static const _maxRuleSetBytes = 4 * 1024 * 1024;
  static const _userAgent = 'EtonifyRouteData/1';

  final GooglePlayRuleSetByteDownloader? _downloadOverride;
  final String? _storageRootOverride;
  Future<GooglePlayRuleSetStatus>? _updateInFlight;

  Future<GooglePlayRuleSetStatus> loadStatus() async {
    final paths = await _storagePaths();
    final playFile = File(paths.geositeGooglePlayPath);
    final googleCnFile = File(paths.geositeGoogleCnPath);
    if (!await _hasUsableRuleSet(playFile) ||
        !await _hasUsableRuleSet(googleCnFile)) {
      return const GooglePlayRuleSetStatus.unavailable();
    }

    final playModified = await playFile.lastModified();
    final googleCnModified = await googleCnFile.lastModified();
    final oldestModified = playModified.isBefore(googleCnModified)
        ? playModified
        : googleCnModified;
    return GooglePlayRuleSetStatus(
      available: true,
      geositeGooglePlayPath: paths.geositeGooglePlayPath,
      geositeGoogleCnPath: paths.geositeGoogleCnPath,
      lastUpdatedMillis: oldestModified.millisecondsSinceEpoch,
    );
  }

  Future<GooglePlayRuleSetStatus> ensureRuleSets({bool force = false}) {
    final inFlight = _updateInFlight;
    if (inFlight != null) return inFlight;
    final future = _ensureRuleSets(force: force);
    _updateInFlight = future;
    return future.whenComplete(() {
      if (identical(_updateInFlight, future)) {
        _updateInFlight = null;
      }
    });
  }

  Future<GooglePlayRuleSetStatus> _ensureRuleSets({required bool force}) async {
    final current = await loadStatus();
    if (!force && current.available && !current.needsDailyUpdate) {
      return current;
    }

    try {
      final (playBytes, googleCnBytes) = await _downloadRuleSetPair();
      final paths = await _storagePaths();
      await Directory(paths.ruleSetDirectoryPath).create(recursive: true);
      await _writeAtomically(paths.geositeGooglePlayPath, playBytes);
      await _writeAtomically(paths.geositeGoogleCnPath, googleCnBytes);
      return await loadStatus();
    } on Exception catch (error, stackTrace) {
      AppLogStore.warning(
        'Google Play routing data',
        'SagerNet geosite refresh failed; keeping validated cache if present: '
            '$error\n$stackTrace',
      );
      return current;
    }
  }

  Future<(Uint8List, Uint8List)> _downloadRuleSetPair() async {
    final playBytes = await _downloadBytes(Uri.parse(googlePlayGeositeUrl));
    final googleCnBytes = await _downloadBytes(Uri.parse(googleCnGeositeUrl));
    if (!isUsableSrsRuleSetBytes(playBytes) ||
        !isUsableSrsRuleSetBytes(googleCnBytes)) {
      throw const FormatException(
        'Downloaded Google Play geosite data is not valid SRS',
      );
    }
    return (playBytes, googleCnBytes);
  }

  Future<Uint8List> _downloadBytes(Uri uri) async {
    final downloadOverride = _downloadOverride;
    if (downloadOverride != null) {
      return downloadOverride(uri);
    }
    final result = await VpnAwareRemoteDownloader.instance.fetchBytes(
      uri: uri,
      maximumBytes: _maxRuleSetBytes,
      headers: const <String, String>{
        'User-Agent': _userAgent,
        'Accept': 'application/octet-stream,*/*',
      },
    );
    return result.bytes ?? Uint8List(0);
  }

  Future<_GooglePlayRuleSetPaths> _storagePaths() async {
    final override = _storageRootOverride;
    final rootPath =
        override ??
        (Platform.isAndroid
            ? await AndroidFilesDir.ensureInitialized()
            : Directory.systemTemp.path);
    final ruleSetDirectory = Directory(
      '$rootPath/route-data/google-play-rule-data/rule-set',
    );
    return _GooglePlayRuleSetPaths(
      ruleSetDirectoryPath: ruleSetDirectory.path,
      geositeGooglePlayPath: '${ruleSetDirectory.path}/geosite-google-play.srs',
      geositeGoogleCnPath: '${ruleSetDirectory.path}/geosite-google@cn.srs',
    );
  }

  Future<bool> _hasUsableRuleSet(File file) async {
    try {
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length <= 4 || length > _maxRuleSetBytes) return false;
      return isUsableSrsRuleSetBytes(await file.readAsBytes());
    } on FileSystemException {
      return false;
    }
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
      if (await backup.exists()) await backup.delete();
      if (await target.exists()) await target.rename(backup.path);
      try {
        await temp.rename(path);
        if (await backup.exists()) await backup.delete();
      } catch (_) {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(path);
        }
        rethrow;
      }
    }
  }
}

class _GooglePlayRuleSetPaths {
  const _GooglePlayRuleSetPaths({
    required this.ruleSetDirectoryPath,
    required this.geositeGooglePlayPath,
    required this.geositeGoogleCnPath,
  });

  final String ruleSetDirectoryPath;
  final String geositeGooglePlayPath;
  final String geositeGoogleCnPath;
}
