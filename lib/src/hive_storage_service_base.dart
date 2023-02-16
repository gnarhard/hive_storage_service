import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorageService {
  final Function adapterRegistrationCallback;
  final CompactionStrategy? compactionStrategy;
  final String hiveSubDirectoryName;
  final secureStorage = FlutterSecureStorage();

  late final Uint8List encryptionKey;
  late final Directory hiveDbDirectory;

  HiveStorageService(
      {this.hiveSubDirectoryName = 'hive',
      required this.adapterRegistrationCallback,
      this.compactionStrategy});

  Future<void> init() async {
    await Hive.initFlutter(hiveSubDirectoryName);
    hiveDbDirectory = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/$hiveSubDirectoryName');
    adapterRegistrationCallback();

    // if key not exists return null
    final storedEncryptionKey = await secureStorage.read(key: 'key');
    if (storedEncryptionKey == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'key',
        value: base64UrlEncode(key),
      );
    }
    final key = await secureStorage.read(key: 'key');
    encryptionKey = base64Url.decode(key!);
    await openBox('appVersion', false);
  }

  Future<void> openBox<T>(String key, bool encrypt) async {
    if (compactionStrategy == null) {
      await Hive.openBox<T>(
        key,
        encryptionCipher: encrypt ? HiveAesCipher(encryptionKey) : null,
      );
    } else {
      await Hive.openBox<T>(
        key,
        compactionStrategy: compactionStrategy!,
        encryptionCipher: encrypt ? HiveAesCipher(encryptionKey) : null,
      );
    }
  }

  /// Get a value from the cache.
  T? get<T>(String key, {T? defaultValue}) {
    final box = Hive.box(key);
    final data = box.get(key, defaultValue: defaultValue);
    return data as T;
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
  Future<void> wipe() async {
    if (await hiveDbDirectory.exists()) {
      hiveDbDirectory.delete(recursive: true);
      hiveDbDirectory.create(); // recreate the directory
    }
  }

  Future<void> nukeOldVersionDBs() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.buildNumber == ''
        ? packageInfo.version
        : '${packageInfo.version}+${packageInfo.buildNumber}';

    final storedVersion = get<String>('appVersion');

    if (storedVersion != currentVersion) {
      await wipe();
      // todo: figure out why this doesn't work
      await openBox('appVersion', false);
      set('appVersion', currentVersion);
    }
  }
}
