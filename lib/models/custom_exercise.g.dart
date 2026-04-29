// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomExerciseAdapter extends TypeAdapter<CustomExercise> {
  @override
  final int typeId = 5;

  @override
  CustomExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomExercise(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      typeIndex: fields[3] as int,
      unit: fields[4] as String,
      muscleGroupIndex: fields[5] as int,
      defaultTarget: fields[6] as int,
      stepSize: fields[7] as int,
      difficulty: fields[8] as int,
      xpPerUnit: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CustomExercise obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.muscleGroupIndex)
      ..writeByte(6)
      ..write(obj.defaultTarget)
      ..writeByte(7)
      ..write(obj.stepSize)
      ..writeByte(8)
      ..write(obj.difficulty)
      ..writeByte(9)
      ..write(obj.xpPerUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
