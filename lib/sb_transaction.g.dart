// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sb_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SBTransactionAdapter extends TypeAdapter<SBTransaction> {
  @override
  final int typeId = 1;

  @override
  SBTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SBTransaction(
      id: fields[0] as int,
      amount: fields[1] as double,
      merchant: fields[2] as String,
      timestamp: fields[3] as DateTime,
      type: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SBTransaction obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.merchant)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SBTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
