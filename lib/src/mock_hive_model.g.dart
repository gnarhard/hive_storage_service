// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_hive_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MockHiveModel _$MockHiveModelFromJson(Map<String, dynamic> json) =>
    MockHiveModel(
      name: json['name'] as String,
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$MockHiveModelToJson(MockHiveModel instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
