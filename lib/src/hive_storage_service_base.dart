import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorageService {
  final Function adapterRegistrationCallback;
  final CompactionStrategy compactionStrategy;
  final String hiveSubDirectoryName;
  final secureStorage = FlutterSecureStorage();

  late final Uint8List encryptionKey;

  HiveStorageService(
      {this.hiveSubDirectoryName = 'hive',
      required this.adapterRegistrationCallback,
      required this.compactionStrategy});

  Future<void> init() async {
    await Hive.initFlutter(hiveSubDirectoryName);

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

    adapterRegistrationCallback();
  }

  Future<Directory> get hiveDb async => Directory(
      '${(await getApplicationDocumentsDirectory()).path}/$hiveSubDirectoryName');

  /// Get a value from the cache.
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    final box = await Hive.openBox(
      key,
      compactionStrategy: compactionStrategy,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final data = await box.get(key, defaultValue: defaultValue) as T?;
    return data;
  }

  /// Create or update a cache entry.
  Future<void> set(String key, dynamic value) async {
    final box = await Hive.openBox(
      key,
      compactionStrategy: compactionStrategy,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    box.put(key, value);
  }

  /// Delete all items stored under the cache key.
  Future<void> destroy(String key) async {
    final box = await Hive.openBox(
      key,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    await box.delete(key);
  }

  /// Delete all data from the cache.
  Future wipe() async {
    final db = await hiveDb;
    if (await db.exists()) {
      db.delete(recursive: true);
    }
  }

  nukeOldVersionDBs() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.buildSignature == ''
        ? packageInfo.version
        : '${packageInfo.version}+${packageInfo.buildSignature}';

    final storedVersion = await get<String>('appVersion');

    if (storedVersion != currentVersion) {
      await wipe();
      await set('appVersion', currentVersion);
    }
  }
}
