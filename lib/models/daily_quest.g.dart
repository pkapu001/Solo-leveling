// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_quest.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyQuestAdapter extends TypeAdapter<DailyQuest> {
  @override
  final int typeId = 2;

  @override
  DailyQuest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyQuest(
      dateKey: fields[0] as String,
      items: (fields[1] as List).cast<QuestItem>(),
      xpEarned: fields[2] as double,
      isCompleted: fields[3] as bool,
      isRestDay: fields[4] as bool,
      streakMultiplier: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DailyQuest obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.xpEarned)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.isRestDay)
      ..writeByte(5)
      ..write(obj.streakMultiplier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
