// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emi_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmiModelAdapter extends TypeAdapter<EmiModel> {
  @override
  final int typeId = 5;

  @override
  EmiModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmiModel(
      id: fields[0] as String,
      itemName: fields[1] as String,
      totalAmount: fields[2] as double,
      monthlyInstallment: fields[3] as double,
      totalMonths: fields[4] as int,
      monthsPaid: fields[5] as int,
      paymentDay: fields[6] as int,
      lastProcessed: fields[7] as DateTime?,
      paymentMethod: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EmiModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.monthlyInstallment)
      ..writeByte(4)
      ..write(obj.totalMonths)
      ..writeByte(5)
      ..write(obj.monthsPaid)
      ..writeByte(6)
      ..write(obj.paymentDay)
      ..writeByte(7)
      ..write(obj.lastProcessed)
      ..writeByte(8)
      ..write(obj.paymentMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmiModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
