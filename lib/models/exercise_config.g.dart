// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseConfigAdapter extends TypeAdapter<ExerciseConfig> {
  @override
  final int typeId = 3;

  @override
  ExerciseConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseConfig(
      exerciseId: fields[0] as String,
      targetAmount: fields[1] as double,
      scalingPct: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.targetAmount)
      ..writeByte(2)
      ..write(obj.scalingPct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
