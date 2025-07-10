import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorageService {
  final Function adapterRegistrationCallback;
  final CompactionStrategy? compactionStrategy;
  final String hiveSubDirectoryName;

  late final Uint8List encryptionKey;
  late final Directory hiveDbDirectory;

  /// Make this a different directory than hiveDbDirectory to save it from nuking.
  late final Directory appVersionDbPath;

  HiveStorageService(
      {this.hiveSubDirectoryName = 'hive',
      required this.adapterRegistrationCallback,
      this.compactionStrategy});

  Future<void> init() async {
    await Hive.initFlutter(hiveSubDirectoryName);
    hiveDbDirectory = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/$hiveSubDirectoryName');
    appVersionDbPath = await getApplicationDocumentsDirectory();

    adapterRegistrationCallback();

    await Hive.openBox('appVersion', path: appVersionDbPath.path);
  }

  Future<void> openBox<T>(String key, bool encrypt) async {
    if (compactionStrategy == null) {
      await Hive.openBox<T>(key);
    } else {
      await Hive.openBox<T>(key, compactionStrategy: compactionStrategy!);
    }
  }

  Future<void> openLazyBox<T>(String key, bool encrypt) async {
    if (compactionStrategy == null) {
      await Hive.openLazyBox<T>(key);
    } else {
      await Hive.openLazyBox<T>(key, compactionStrategy: compactionStrategy!);
    }
  }

  /// Get a value from the cache.
  T? get<T>(String key, {T? defaultValue}) {
    final box = Hive.box(key);
    final data = box.get(key, defaultValue: defaultValue);
    return data;
  }

  /// Create or update a cache entry.
  void set(String key, dynamic value) {
    final box = Hive.box(key);
    box.put(key, value);
  }

  /// Delete all items stored under the cache key.
  void destroy(String key) {
    final box = Hive.box(key);
    box.delete(key);
  }

  /// Delete all data from the cache.
  Future<void> truncate() async {
    if (await hiveDbDirectory.exists()) {
      await Hive.close();
      await hiveDbDirectory.delete(recursive: true);
      await hiveDbDirectory.create(); // recreate the directory
    }
  }

  Future<bool> nukeOldVersionDBs() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.buildNumber == ''
        ? packageInfo.version
        : '${packageInfo.version}+${packageInfo.buildNumber}';

    final appVersionBox =
        await Hive.openBox('appVersion', path: appVersionDbPath.path);
    final storedVersion = await appVersionBox.get('appVersion');

    if (storedVersion != currentVersion) {
      await truncate();

      final appVersionBox =
          await Hive.openBox('appVersion', path: appVersionDbPath.path);

      appVersionBox.put('appVersion', currentVersion);
      return true;
    }

    return false;
  }
}
