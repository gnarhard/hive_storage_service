import 'package:flutter/widgets.dart' show Key;
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_storage_service/src/mock_hive_model.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:hive_storage_service/src/empty_app.dart' as app;

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
                  compactionStrategy: (entries, deletedEntries) =>
                      deletedEntries > 10,
                ));
        await service.init();
        registered = true;
      }
      await service.openBox(storageKey, true);
      app.main();
    });

    tearDown(() => service.destroy(storageKey));

    testWidgets("can set data", (tester) async {
      await tester.pumpAndSettle();
      service.set(storageKey, MockHiveModel.make());

      final mockHiveModel = service.get<MockHiveModel>(storageKey);

      expect(mockHiveModel, isNotNull);
    });

    testWidgets("can wipe data", (tester) async {
      await tester.pumpAndSettle();
      await service.wipe();

      final bool dbExists = await service.hiveDbDirectory.exists();

      expect(dbExists, false);
    });

    testWidgets("can nuke db after version change", (tester) async {
      await tester.pumpAndSettle();

      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.buildSignature == ''
          ? packageInfo.version
          : '${packageInfo.version}+${packageInfo.buildSignature}';
          
      service.set('appVersion', currentVersion);
      final storedVersion = service.get<String>('appVersion');

      expect(storedVersion, currentVersion);
      bool dbExists = await service.hiveDbDirectory.exists();

      // expect that new db directory was created
      expect(dbExists, true);

      await service.nukeOldVersionDBs();
      dbExists = await service.hiveDbDirectory.exists();

      // expect that db still exists after versions match
      expect(dbExists, true);

      service.set('appVersion', '1.0.0+99');
      await service.nukeOldVersionDBs();
      dbExists = await service.hiveDbDirectory.exists();

      // expect that db was deleted after versions don't match
      expect(dbExists, false);
    });
  });
}
