// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionModelAdapter extends TypeAdapter<SubscriptionModel> {
  @override
  final int typeId = 2;

  @override
  SubscriptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      category: fields[2] as String,
      paymentMethod: fields[3] as String,
      note: fields[4] as String,
      paymentDay: fields[5] as int,
      lastProcessed: fields[6] as DateTime?,
      paymentHour: fields[7] == null ? 0 : fields[7] as int,
      paymentMinute: fields[8] == null ? 0 : fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.paymentMethod)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.paymentDay)
      ..writeByte(6)
      ..write(obj.lastProcessed)
      ..writeByte(7)
      ..write(obj.paymentHour)
      ..writeByte(8)
      ..write(obj.paymentMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
