// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class MockHiveModelAdapter extends TypeAdapter<MockHiveModel> {
  @override
  final typeId = 0;

  @override
  MockHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MockHiveModel(
      name: fields[1] as String,
      id: (fields[0] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MockHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
