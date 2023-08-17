import 'dart:math';

import 'package:hive_flutter/adapters.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:faker/faker.dart';

part 'mock_hive_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class MockHiveModel {
  @HiveField(0)
  final int id;
  @HiveField(1)
  String name;

  MockHiveModel({
    required this.name,
    required this.id,
  });

  Map<String, dynamic> toJson() => _$MockHiveModelToJson(this);

  factory MockHiveModel.fromJson(Map<String, dynamic> json) =>
      _$MockHiveModelFromJson(json);

  factory MockHiveModel.make() {
    Faker faker = Faker();
    Random random = Random();
    return MockHiveModel(name: faker.animal.name(), id: random.nextInt(10));
  }
}
