// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configuracion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfiguracionAdapter extends TypeAdapter<Configuracion> {
  @override
  final int typeId = 1;

  @override
  Configuracion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Configuracion(
      nombreNegocio: fields[0] as String,
      iva: fields[1] as double,
      telefono: fields[2] as String,
      direccion: fields[3] as String,
      logoPath: fields[4] as String?,
      directorioDescarga: fields[6] as String?,
    )..bienvenida = fields[5] as String?;
  }

  @override
  void write(BinaryWriter writer, Configuracion obj) {
    writer
      ..writeByte(7)
      ..writeByte(6)
      ..write(obj.directorioDescarga)
      ..writeByte(0)
      ..write(obj.nombreNegocio)
      ..writeByte(1)
      ..write(obj.iva)
      ..writeByte(2)
      ..write(obj.telefono)
      ..writeByte(3)
      ..write(obj.direccion)
      ..writeByte(4)
      ..write(obj.logoPath)
      ..writeByte(5)
      ..write(obj.bienvenida);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfiguracionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
