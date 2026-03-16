import 'package:hive/hive.dart';
part 'configuracion.g.dart';

@HiveType(typeId: 1)
class Configuracion extends HiveObject {
  @HiveField(6)
  String? directorioDescarga;

  @HiveField(0)
  String nombreNegocio;

  @HiveField(1)
  double iva;

  @HiveField(2)
  String telefono;

  @HiveField(3)
  String direccion;

  @HiveField(4)
  String? logoPath; // Ruta local de la imagen

  @HiveField(5)
  String? bienvenida; // o final String bienvenida;


  Configuracion({
    required this.nombreNegocio,
    required this.iva,
    required this.telefono,
    required this.direccion,
    this.logoPath,
    this.directorioDescarga,
  });
}

