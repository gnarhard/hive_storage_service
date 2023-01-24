import 'package:hive_flutter/hive_flutter.dart';

class HiveStorageService {
  /// A registry of all the available boxes (aka tables).
  List<String> cacheKeys = [];

  final Function adapterRegistrationCallback;

  HiveStorageService({required this.adapterRegistrationCallback});

  Future<void> init() async {
    await Hive.initFlutter();
    adapterRegistrationCallback();
  }

  /// Get a value from the cache.
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    final box = await Hive.openBox(key);
    final data = await box.get(key, defaultValue: defaultValue) as T?;
    await box.close();
    return data;
  }

  /// Create or update a cache entry.
  Future<void> set(String key, dynamic value) async {
    final box = await Hive.openBox(key);
    box.put(key, value);
    await box.close();
  }

  /// Delete all items stored under the cache key.
  Future<void> destroy(String key) async {
    final box = await Hive.openBox(key);
    await box.delete(key);
    await box.close();
  }

  /// Delete all data from the cache.
  Future wipe() async {
    var futures = <Future>[];
    for (String cacheKey in cacheKeys) {
      futures.add(Hive.openBox(cacheKey));
    }
    await Future.wait(futures);
    Hive.deleteFromDisk();
  }

  /// Close all open Hive boxes.
  Future dispose() async {
    var futures = <Future>[];
    for (String cacheKey in cacheKeys) {
      futures.add(Hive.box(cacheKey).close());
    }
    await Future.wait(futures);
  }
}
