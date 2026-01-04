import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:faker/faker.dart';

part 'mock_hive_model.g.dart';

@JsonSerializable()
class MockHiveModel {
  final int id;
  String name;

  MockHiveModel({required this.name, required this.id});

  Map<String, dynamic> toJson() => _$MockHiveModelToJson(this);

  factory MockHiveModel.fromJson(Map<String, dynamic> json) =>
      _$MockHiveModelFromJson(json);

  factory MockHiveModel.make() {
    Faker faker = Faker();
    Random random = Random();
    return MockHiveModel(name: faker.animal.name(), id: random.nextInt(10));
  }
}
