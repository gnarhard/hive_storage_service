import 'package:hive_storage_service/hive_storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'hive_storage_service_test.mocks.dart';
import 'mock_hive_model.dart';

@GenerateNiceMocks([MockSpec<HiveStorageService>()])
void main() {
  group('Hive Storage Service', () {
    final MockHiveStorageService storageService = MockHiveStorageService();
    const cacheKey = 'mock_hive_model';

    setUp(() async {});
    tearDown(() async {});

    test("Can initialize correctly.", () async {
      when(storageService.init()).thenAnswer((_) => Future<void>.value());
      expect(storageService, isNotNull);
    });

    test("Can set and get data.", () async {
      final mockHiveModel = MockHiveModel(id: 1, name: 'Test');
      final future = Future.value(mockHiveModel);

      when(storageService.set(cacheKey, mockHiveModel))
          .thenAnswer((_) async => mockHiveModel);

      when(storageService.get<MockHiveModel>(cacheKey))
          .thenAnswer((_) => future);

      expect(await storageService.get<MockHiveModel>(cacheKey), mockHiveModel);
    });

    test("Can delete data.", () async {
      final mockHiveModels = [
        MockHiveModel(id: 1, name: 'Test'),
        MockHiveModel(id: 2, name: 'Test2'),
        MockHiveModel(id: 3, name: 'Test3'),
      ];
      final future = Future.value(mockHiveModels.sublist(2));

      when(storageService.set(cacheKey, mockHiveModels))
          .thenAnswer((_) async => mockHiveModels);

      when(storageService.destroy(cacheKey, mockHiveModels))
          .thenAnswer((_) async => future);

      expect(await storageService.get<MockHiveModel>(cacheKey), mockHiveModel);
    });
  });
}
