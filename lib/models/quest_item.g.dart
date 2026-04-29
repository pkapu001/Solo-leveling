// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestItemAdapter extends TypeAdapter<QuestItem> {
  @override
  final int typeId = 1;

  @override
  QuestItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestItem(
      exerciseId: fields[0] as String,
      targetAmount: fields[1] as double,
      completedAmount: fields[2] as double,
      scalingPct: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, QuestItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.targetAmount)
      ..writeByte(2)
      ..write(obj.completedAmount)
      ..writeByte(3)
      ..write(obj.scalingPct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
