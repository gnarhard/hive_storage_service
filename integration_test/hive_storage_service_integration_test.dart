import 'package:flutter/widgets.dart' show Key;
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_storage_service/src/mock_hive_model.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../example/hive_storage_service_example.dart' as app;

void main() {
  group('Hive Storage Service', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    late final service = GetIt.I<HiveStorageService>();
    bool registered = false;

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
    });

    testWidgets("can set data", (tester) async {
      app.main();
      await tester.pumpAndSettle();
      final Finder setDataButton = find.byKey(const Key('set-data-button'));

      await tester.tap(setDataButton);
      await tester.pumpAndSettle();

      final mockHiveModel = await service.get<MockHiveModel>('test');

      expect(mockHiveModel!.name, 'test');
    });

    testWidgets("can wipe data", (tester) async {
      app.main();
      await tester.pumpAndSettle();
      final Finder wipeDataButton = find.byKey(const Key('wipe-data-button'));
      final Finder setDataButton = find.byKey(const Key('set-data-button'));

      await tester.tap(setDataButton);
      await tester.pumpAndSettle();

      await tester.tap(wipeDataButton);
      await tester.pumpAndSettle();

      final hiveDb = await service.hiveDb;
      final bool dbExists = await hiveDb.exists();

      expect(dbExists, false);
    });

    testWidgets("can nuke db after version change", (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final hiveDb = await service.hiveDb;

      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.buildSignature == ''
          ? packageInfo.version
          : '${packageInfo.version}+${packageInfo.buildSignature}';
      await service.set('appVersion', currentVersion);
      final storedVersion = await service.get<String>('appVersion');

      expect(storedVersion, currentVersion);
      bool dbExists = await hiveDb.exists();

      // expect that new db directory was created
      expect(dbExists, true);

      await service.nukeOldVersionDBs();
      dbExists = await hiveDb.exists();

      // expect that db still exists after versions match
      expect(dbExists, true);

      await service.set('appVersion', '1.0.0+99');
      await service.nukeOldVersionDBs();
      dbExists = await hiveDb.exists();

      // expect that db was deleted after versions don't match
      expect(dbExists, false);
    });
  });
}
