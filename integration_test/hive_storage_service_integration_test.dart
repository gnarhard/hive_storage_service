import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_storage_service/src/mock_hive_model.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hive_storage_service/src/empty_app.dart' as app;

// NOTE: Tests passing as of 1.3.2026

void main() {
  group('Hive Storage Service', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    late final HiveStorageService service;
    bool registered = false;
    const String storageKey = 'test';

    setUp(() async {
      if (!registered) {
        service = HiveStorageService(
          adapterRegistrationCallback: () {
            Hive.registerAdapter(MockHiveModelAdapter());
          },
        );
        await service.init();
        registered = true;
      }

      app.main();
    });

    testWidgets("can set data", (tester) async {
      await tester.pumpAndSettle();

      await service.openBox<MockHiveModel>(storageKey, true);

      final mockModel = MockHiveModel.make();
      service.set<MockHiveModel>(storageKey, mockModel);

      final mockHiveModel = service.get<MockHiveModel>(storageKey);

      expect(mockHiveModel, isNotNull);
      expect(mockHiveModel == mockModel, true);

      service.destroy<MockHiveModel>(storageKey);
    });

    testWidgets("can wipe data", (tester) async {
      await tester.pumpAndSettle();
      bool dbExists = await service.hiveDbDirectory.exists();
      expect(dbExists, true);

      // store new data
      await service.openBox<int>('test_number', false);
      service.set<int>('test_number', 1);

      await service.truncate();
      dbExists = await service.hiveDbDirectory.exists();

      // We are recreating the database in wipe
      expect(dbExists, true);

      final boxExists = await Hive.boxExists('test_number');
      expect(boxExists, false);
    });

    testWidgets("can nuke db after version change", (tester) async {
      await tester.pumpAndSettle();

      final packageInfo = await PackageInfo.fromPlatform();

      // add data to hiveDbDirectory so the size can be compared later
      await service.openBox<int>('test_number', false);
      service.set<int>('test_number', 1);

      final box = await Hive.openBox<String>('buildNumber',
          path: service.buildNumberDbPath.path);
      box.put('buildNumber', packageInfo.buildNumber);
      final storedVersion = box.get('buildNumber');

      expect(storedVersion, packageInfo.buildNumber);

      FileStat originalDbStat = await service.hiveDbDirectory.stat();
      await service.nukeOldVersionDBs();
      FileStat newDbStat = await service.hiveDbDirectory.stat();

      // expect that db sizes remain the same after versions match
      expect(originalDbStat.size, newDbStat.size);
      bool boxExists = await Hive.boxExists('buildNumber',
          path: service.buildNumberDbPath.path);
      expect(boxExists, true);

      final newBox = await Hive.openBox<String>('buildNumber',
          path: service.buildNumberDbPath.path);
      newBox.put('buildNumber', 'test_version_change');
      await service.nukeOldVersionDBs();
      newDbStat = await service.hiveDbDirectory.stat();

      // expect that db was truncated after versions don't match
      expect(originalDbStat.size, isNot(newDbStat.size));

      // box should have been recreated
      boxExists = await Hive.boxExists('buildNumber',
          path: service.buildNumberDbPath.path);
      expect(boxExists, true);
    });
  });
}
