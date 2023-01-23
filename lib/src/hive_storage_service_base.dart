import 'package:hive_flutter/hive_flutter.dart';

/// Controls for the management of cache.
class StorageService {
  /// A registry of all the available boxes (aka tables).
  List<String> cacheKeys = [];

  final Function adapterRegistrationCallback;

  StorageService({required this.adapterRegistrationCallback});

  Future<void> init() async {
    await Hive.initFlutter();
  }

  /// Get a value from the cache.
  @override
  Future<T?> get<T>(String key) async {
    return await Hive.openBox(key) as T?;
  }

  /// Create or update a cache entry.
  @override
  Future<void> set(String key, dynamic value) async {
    final box = await Hive.openBox(key);
    box.put(key, value);
  }

  /// Delete a single item from the cache.
  Future destroy(String key) async {
    final box = await Hive.openBox(key);
    return await box.delete(key);
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
