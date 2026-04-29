// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitExpenseModelAdapter extends TypeAdapter<SplitExpenseModel> {
  @override
  final int typeId = 7;

  @override
  SplitExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitExpenseModel(
      id: fields[0] as String,
      tripId: fields[1] as String,
      amount: fields[2] as double,
      description: fields[3] as String,
      paidBy: fields[4] as String,
      splitAmong: (fields[5] as List).cast<String>(),
      date: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SplitExpenseModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.paidBy)
      ..writeByte(5)
      ..write(obj.splitAmong)
      ..writeByte(6)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
