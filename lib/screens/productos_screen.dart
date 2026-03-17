import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/producto.dart';
import 'package:flutter/services.dart';
import '../services/anuncios_service.dart';

class PrimeraLetraMayusculaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text;
    final corregido = text[0].toUpperCase() + text.substring(1);
    return newValue.copyWith(text: corregido, selection: newValue.selection);
  }
}

class _CampoTextoBonito extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String label;
  final IconData icon;
  final List<TextInputFormatter>? inputFormatters;

  const _CampoTextoBonito({
    required this.controller,
    this.keyboardType,
    required this.label,
    required this.icon,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.green[700]),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade300, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 16),
      inputFormatters: inputFormatters,
    );
  }
}

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {

  void _mostrarAlertaProductoExistente(String nombre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Producto duplicado'),
        content: Text('El producto \"$nombre\" ya está registrado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final Box<Producto> _productosBox = Hive.box<Producto>('productosBox');

  void _agregarProducto() {
    final nombre = _nombreController.text.trim();
    final stock = int.tryParse(_stockController.text) ?? 0;

    // 🔁 Reemplazar coma por punto y convertir a double
    final precioTexto = _precioController.text.replaceAll(',', '.');
    final precio = double.tryParse(precioTexto);

    if (nombre.isEmpty || precio == null || precio <= 0 || stock < 0) {
      // Mostrar un error si falta algún dato válido
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Datos inválidos'),
          content: const Text('Por favor, completa todos los campos correctamente. El precio debe ser mayor a 0.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Verificar si el producto ya existe (ignorando mayúsculas/minúsculas)
    final existe = _productosBox.values.any(
      (p) => p.nombre.toLowerCase() == nombre.toLowerCase()
    );

    if (existe) {
      _mostrarAlertaProductoExistente(nombre);
      return;
    }

    final nuevoProducto = Producto(
      nombre: nombre,
      precio: precio,
      stock: stock,
    );
    _productosBox.add(nuevoProducto);

    Navigator.pop(context); // cerrar el diálogo

    // Limpiar campos
    _nombreController.clear();
    _precioController.clear();
    _stockController.clear();
  }


  void _mostrarDialogoLimiteConOpcionRewarded() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Límite alcanzado'),
        content: Text(
          'Has alcanzado el límite de 7 productos en la versión gratuita.\n\n¿Quieres ver un anuncio para agregar 1 producto adicional?',
        ),
        actions: [
          TextButton(
            child: Text('Ver anuncio'),
            onPressed: () {
              Navigator.of(context).pop();
              AnunciosService().mostrarRewarded(context, () {
                setState(() {}); // refresca para que se aplique el extra
              });
            },
          ),
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }


  void _mostrarDialogoEditarProducto(int index, Producto producto) {
    final _editNombreController = TextEditingController(text: producto.nombre);
    final _editPrecioController = TextEditingController(text: producto.precio.toString());
    final _editStockController = TextEditingController(text: producto.stock.toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Editar Producto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[700])),
              const SizedBox(height: 18),
              _CampoTextoBonito(
                controller: _editNombreController,
                label: 'Nombre',
                icon: Icons.shopping_bag,
              ),
              const SizedBox(height: 10),
              _CampoTextoBonito(
                controller: _editPrecioController,
                label: 'Precio',
                icon: Icons.attach_money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              _CampoTextoBonito(
                controller: _editStockController,
                label: 'Stock',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  final newNombre = _editNombreController.text.trim();
                  final newPrecio = double.tryParse(_editPrecioController.text) ?? 0;
                  final newStock = int.tryParse(_editStockController.text) ?? 0;

                  if (newNombre.isEmpty || newPrecio <= 0) return;

                  final prodEdit = _productosBox.getAt(index);
                  prodEdit?.nombre = newNombre;
                  prodEdit?.precio = newPrecio;
                  prodEdit?.stock = newStock;
                  prodEdit?.save();

                  Navigator.of(context).pop();
                  setState(() {});
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoNuevoProducto() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nuevo Producto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[300])),
              const SizedBox(height: 18),
              _CampoTextoBonito(
                controller: _nombreController,
                label: 'Nombre',
                icon: Icons.shopping_bag,
                inputFormatters: [PrimeraLetraMayusculaFormatter()],  // <-- AGREGADO
              ),
              const SizedBox(height: 10),
              _CampoTextoBonito(
                controller: _precioController,
                label: 'Precio',
                icon: Icons.attach_money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              _CampoTextoBonito(
                controller: _stockController,
                label: 'Stock',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _agregarProducto,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _eliminarProducto(int index) {
    final producto = _productosBox.getAt(index);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${producto?.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _productosBox.deleteAt(index);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _intentarAbrirDialogoNuevo() {
    final limiteBase = 7;
    final extra = AnunciosService().productosExtra;
    final totalPermitido = limiteBase + extra;

    if (_productosBox.length >= totalPermitido) {
      _mostrarDialogoLimiteConOpcionRewarded();
    } else {
      _mostrarDialogoNuevoProducto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Productos',
          style: TextStyle(
            fontSize: 26,            // Tamaño de fuente más grande
            fontWeight: FontWeight.bold,
            color: Colors.white,     // Color del texto
            letterSpacing: 1.1,      // Espaciado entre letras (opcional)
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ValueListenableBuilder(
          valueListenable: _productosBox.listenable(),
          builder: (context, Box<Producto> box, _) {
            if (box.isEmpty) {
              return Center(child: Text('No hay productos registrados', style: TextStyle(color: Colors.grey[600])));
            }
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, i) {
                final prod = box.getAt(i);
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(Icons.inventory, color: Colors.green[700]),
                    ),
                    title: Text(prod?.nombre ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Stock: ${prod?.stock ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${prod?.precio.toStringAsFixed(2) ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _mostrarDialogoEditarProducto(i, prod!),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[400]),
                          onPressed: () => _eliminarProducto(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        onPressed: _intentarAbrirDialogoNuevo,
      ),

      bottomNavigationBar: AnunciosService().obtenerBannerWidget(),
    );
  }
}

