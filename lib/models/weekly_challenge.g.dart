// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_challenge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklyChallengeAdapter extends TypeAdapter<WeeklyChallenge> {
  @override
  final int typeId = 6;

  @override
  WeeklyChallenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyChallenge(
      weekKey: fields[0] as String,
      triggerDay: fields[1] as int,
      exerciseId: fields[2] as String,
      targetAmount: fields[3] as double,
      completedAmount: fields[4] as double,
      isCompleted: fields[5] as bool,
      xpEarned: fields[6] as double,
      bonusVolumeAwarded: fields[7] as bool,
      skippedWeek: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyChallenge obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.weekKey)
      ..writeByte(1)
      ..write(obj.triggerDay)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.targetAmount)
      ..writeByte(4)
      ..write(obj.completedAmount)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.xpEarned)
      ..writeByte(7)
      ..write(obj.bonusVolumeAwarded)
      ..writeByte(8)
      ..write(obj.skippedWeek);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
