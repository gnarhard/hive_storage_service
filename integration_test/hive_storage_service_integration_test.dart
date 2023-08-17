import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_storage_service/src/mock_hive_model.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hive_storage_service/src/empty_app.dart' as app;

// NOTE: Tests passing as of 8.16.2023

void main() {
  group('Hive Storage Service', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    late final service = GetIt.I<HiveStorageService>();
    bool registered = false;
    const String storageKey = 'test';

    setUp(() async {
      if (!registered) {
        GetIt.I
            .registerLazySingleton<HiveStorageService>(() => HiveStorageService(
                  adapterRegistrationCallback: () {
                    Hive.registerAdapter(MockHiveModelAdapter());
                  },
                ));

        await service.init();
        registered = true;
      }

      await service.openBox(storageKey, true);
      app.main();
    });

    testWidgets("can set data", (tester) async {
      await tester.pumpAndSettle();
      service.set(storageKey, MockHiveModel.make());

      final mockHiveModel = service.get<MockHiveModel>(storageKey);

      expect(mockHiveModel, isNotNull);

      service.destroy(storageKey);
    });

    testWidgets("can wipe data", (tester) async {
      await tester.pumpAndSettle();
      bool dbExists = await service.hiveDbDirectory.exists();
      expect(dbExists, true);

      // store new data
      await service.openBox('test_number', false);
      service.set('test_number', 1);

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
      final String currentVersion = packageInfo.buildNumber == ''
          ? packageInfo.version
          : '${packageInfo.version}+${packageInfo.buildNumber}';

      service.set('appVersion', currentVersion);
      final storedVersion = service.get<String>('appVersion');

      expect(storedVersion, currentVersion);

      FileStat dbStat = await service.hiveDbDirectory.stat();
      await service.nukeOldVersionDBs();
      FileStat newDbStat = await service.hiveDbDirectory.stat();

      // expect that db sizes exists after versions match
      expect(dbStat.size == newDbStat.size, true);

      service.set('appVersion', '1.0.0+99');
      await service.nukeOldVersionDBs();
      newDbStat = await service.hiveDbDirectory.stat();

      // expect that db was deleted after versions don't match
      expect(dbStat.size > newDbStat.size, true);
    });
  });
}
