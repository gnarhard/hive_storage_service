import 'package:hive_ce_flutter/adapters.dart';
import 'package:hive_storage_service/src/mock_hive_model.dart';

@GenerateAdapters([
  AdapterSpec<MockHiveModel>(),
])
part 'hive_adapters.g.dart';
