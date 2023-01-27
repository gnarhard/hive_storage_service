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

  void addCacheKey(String key) {
    if (!cacheKeys.contains(key)) {
      cacheKeys.add(key);
    }
  }

  /// Get a value from the cache.
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    addCacheKey(key);
    final box = await Hive.openBox(key);
    final data = await box.get(key, defaultValue: defaultValue) as T?;
    return data;
  }

  /// Create or update a cache entry.
  Future<void> set(String key, dynamic value) async {
    addCacheKey(key);
    final box = await Hive.openBox(key);
    await box.compact();
    box.put(key, value);
  }

  /// Delete all items stored under the cache key.
  Future<void> destroy(String key) async {
    final box = await Hive.openBox(key);
    await box.delete(key);
    cacheKeys.removeWhere((element) => element == key);
  }

  /// Delete all data from the cache.
  Future wipe() async {
    var futures = <Future>[];
    for (String cacheKey in cacheKeys) {
      futures.add(Hive.openBox(cacheKey));
    }
    await Future.wait(futures);
    Hive.deleteFromDisk();
    await dispose();
    cacheKeys = [];
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
