import 'package:hive/hive.dart';

part 'producto.g.dart';

@HiveType(typeId: 0)
class Producto extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  double precio;

  @HiveField(2)
  int stock;

  @HiveField(3)
  String? imagenPath; // 👈 NUEVO

  Producto({
    required this.nombre,
    required this.precio,
    required this.stock,
    this.imagenPath,
  });
}
