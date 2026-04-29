// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 0;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      name: fields[0] as String,
      totalXp: fields[1] as double,
      streakDays: fields[2] as int,
      startDate: fields[3] as DateTime,
      lastCompletedDate: fields[4] as DateTime?,
      lastScaledWeek: fields[5] as int,
      notificationHour: fields[6] as int,
      notificationMinute: fields[7] as int,
      useImperial: fields[8] as bool,
      eveningNotifHour: fields[9] as int,
      eveningNotifMinute: fields[10] as int,
      longestStreak: fields[11] as int? ?? 0,
      lastRestDayKey: fields[12] as String?,
      abilityLocked: (fields[13] as List?)?.cast<String>() ?? [],
      challengeBonusVolume: (fields[14] as Map?)?.cast<String, double>() ?? {},
      exerciseBonusVolume: (fields[15] as Map?)?.cast<String, double>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.totalXp)
      ..writeByte(2)
      ..write(obj.streakDays)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.lastCompletedDate)
      ..writeByte(5)
      ..write(obj.lastScaledWeek)
      ..writeByte(6)
      ..write(obj.notificationHour)
      ..writeByte(7)
      ..write(obj.notificationMinute)
      ..writeByte(8)
      ..write(obj.useImperial)
      ..writeByte(9)
      ..write(obj.eveningNotifHour)
      ..writeByte(10)
      ..write(obj.eveningNotifMinute)
      ..writeByte(11)
      ..write(obj.longestStreak)
      ..writeByte(12)
      ..write(obj.lastRestDayKey)
      ..writeByte(13)
      ..write(obj.abilityLocked)
      ..writeByte(14)
      ..write(obj.challengeBonusVolume)
      ..writeByte(15)
      ..write(obj.exerciseBonusVolume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
