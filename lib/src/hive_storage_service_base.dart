import 'dart:io' show Directory;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorageService {
  final Function adapterRegistrationCallback;
  static const String subDirectory = 'hive';
  final CompactionStrategy compactionStrategy;

  HiveStorageService(
      {required this.adapterRegistrationCallback,
      required this.compactionStrategy});

  Future<void> init() async {
    await Hive.initFlutter(subDirectory);

    adapterRegistrationCallback();
  }

  /// Get a value from the cache.
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    final box = await Hive.openBox(key, compactionStrategy: compactionStrategy);
    final data = await box.get(key, defaultValue: defaultValue) as T?;
    return data;
  }

  /// Create or update a cache entry.
  Future<void> set(String key, dynamic value) async {
    final box = await Hive.openBox(key, compactionStrategy: compactionStrategy);
    box.put(key, value);
  }

  /// Delete all items stored under the cache key.
  Future<void> destroy(String key) async {
    final box = await Hive.openBox(key);
    await box.delete(key);
  }

  /// Delete all data from the cache.
  Future wipe() async {
    var appDir = await getApplicationDocumentsDirectory();
    var hiveDb = Directory('${appDir.path}/$subDirectory');
    if (await hiveDb.exists()) {
      hiveDb.delete(recursive: true);
    }
  }
}
