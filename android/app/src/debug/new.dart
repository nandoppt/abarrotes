import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/producto.dart';
import 'package:flutter/services.dart';
import '../services/anuncios_service.dart';

class PrimeraLetraMayusculaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue) {
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
  final String? hint;
  final IconData icon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const _CampoTextoBonito({
    super.key, // Añadir super.key
    required this.controller,
    this.keyboardType,
    required this.label,
    this.hint,
    required this.icon,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    // Define el estilo del borde una vez
    final OutlineInputBorder defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.green.shade100),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.green[700]),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 14),
        border: defaultBorder,
        // Usa el borde predeterminado
        enabledBorder: defaultBorder,
        // Usa el borde predeterminado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade300, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
  // Eliminar controladores no utilizados
  // final _nombreController = TextEditingController();
  // final _precioController = TextEditingController();
  // final _stockController = TextEditingController();

  final Box<Producto> _productosBox = Hive.box<Producto>('productosBox');
  final AnunciosService _anunciosService = AnunciosService(); // Instancia de AnunciosService

  void _mostrarFormularioProducto({Producto? productoAEditar, int? index}) {
    final bool esEdicion = productoAEditar != null;

    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(
        text: productoAEditar?.nombre ?? '');
    final precioCtrl = TextEditingController(
        text: productoAEditar?.precio.toString() ?? '');
    final stockCtrl = TextEditingController(
        text: productoAEditar?.stock.toString() ?? '');

    // Se asegura de liberar los controladores cuando el BottomSheet se cierra
    // Esto es importante si los controladores se crearan en el nivel de la clase
    // Pero como son locales a esta función, el garbage collector los manejará.
    // Sin embargo, si alguna vez los conviertes en miembros de clase, necesitarías
    // añadir `dispose()` en el `dispose()` de tu `State`.

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom,
            left: 22, right: 22, top: 22,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 15),
                Text(
                  esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                  style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700]),
                ),
                const SizedBox(height: 18),
                _CampoTextoBonito(
                  controller: nombreCtrl,
                  label: 'Nombre',
                  icon: Icons.shopping_bag,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [PrimeraLetraMayusculaFormatter()],
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) return 'El nombre es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _CampoTextoBonito(
                  controller: precioCtrl,
                  label: 'Precio',
                  icon: Icons.attach_money,
                  textInputAction: TextInputAction.next,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) return 'Ingresa un precio';
                    if (double.tryParse(value.replaceAll(',', '.')) == null)
                      return 'Precio inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _CampoTextoBonito(
                  controller: stockCtrl,
                  label: 'Stock',
                  icon: Icons.numbers,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) return 'Ingresa el stock';
                    if (int.tryParse(value) == null) return 'Stock inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final nombre = nombreCtrl.text.trim();
                      final precio = double.parse(precioCtrl.text.replaceAll(
                          ',', '.'));
                      final stock = int.parse(stockCtrl.text);

                      // --- VALIDACIÓN DE DUPLICADOS ---
                      bool existe = _productosBox.values.any((p) =>
                      p.nombre.toLowerCase() == nombre.toLowerCase() &&
                          (esEdicion
                              ? p.key != productoAEditar!.key
                              : true) // Excluye el propio producto si estamos editando
                      );

                      if (existe) {
                        _mostrarAlertaProductoExistente(nombre);
                        return; // Detiene el guardado
                      }

                      // --- GUARDAR O ACTUALIZAR ---
                      if (esEdicion) {
                        productoAEditar!.nombre =
                            nombre; // productoAEditar ya no es nulo aquí
                        productoAEditar.precio = precio;
                        productoAEditar.stock = stock;
                        productoAEditar.save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(
                              'Producto actualizado exitosamente'),
                              backgroundColor: Colors.blue),
                        );
                      } else {
                        final nuevoProducto = Producto(nombre: nombre,
                            precio: precio,
                            stock: stock);
                        _productosBox.add(nuevoProducto);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Producto agregado exitosamente'),
                              backgroundColor: Colors.green),
                        );
                      }

                      Navigator.pop(context); // Cierra el BottomSheet
                      // No se necesita setState() si la UI depende de ValueListenableBuilder
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: Text(
                      esEdicion ? 'Guardar Cambios' : 'Guardar Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esEdicion ? Colors.blue[400] : Colors
                        .green[700],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Importante: Liberar recursos de los controladores cuando el BottomSheet se cierra
      nombreCtrl.dispose();
      precioCtrl.dispose();
      stockCtrl.dispose();
    });
  }

  void _mostrarAlertaProductoExistente(String nombre) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text('Producto duplicado'), // Added const
            content: Text('El producto "$nombre" ya está registrado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'), // Added const
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoLimiteConOpcionRewarded() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text('Límite alcanzado'), // Added const
            content: const Text( // Added const
              'Has alcanzado el límite de 7 productos en la versión gratuita.\n\n¿Quieres ver un anuncio para agregar 1 producto adicional?',
            ),
            actions: [
              TextButton(
                child: const Text('Ver anuncio'), // Added const
                onPressed: () {
                  Navigator.of(context).pop();
                  _anunciosService.mostrarRewarded(
                      context, () { // Usar la instancia
                    setState(() {}); // refresca para que se aplique el extra
                  });
                },
              ),
              TextButton(
                child: const Text('Cancelar'), // Added const
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  void _confirmarEliminarProducto(int index, String nombre) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Eliminar Producto'),
            content: Text(
                '¿Estás seguro de que deseas eliminar "$nombre"? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    'Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400]),
                onPressed: () {
                  _productosBox.deleteAt(index);
                  Navigator.pop(context);
                  // No se necesita setState() si la UI depende de ValueListenableBuilder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto eliminado'),
                        backgroundColor: Colors.red),
                  );
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  // Se corrige la función para ser usada
  void _intentarAbrirFormularioNuevoProducto() {
    const int limiteBase = 7;
    final int productosExtra = _anunciosService
        .productosExtra; // Usar la instancia de servicio
    final int totalPermitido = limiteBase + productosExtra;

    if (_productosBox.length >= totalPermitido) {
      _mostrarDialogoLimiteConOpcionRewarded();
    } else {
      _mostrarFormularioProducto(); // Abre el formulario para un nuevo producto
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
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ValueListenableBuilder(
          valueListenable: _productosBox.listenable(),
          builder: (context, Box<Producto> box, _) {
            if (box.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 80,
                        color: Colors.grey[350]),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no tienes productos',
                      style: TextStyle(fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca "Agregar" para registrar tu inventario.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, i) {
                final prod = box.getAt(i);
                // Validación para evitar productos nulos si Hive retorna null (poco probable con box.getAt(i))
                if (prod == null) return const SizedBox.shrink();

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(Icons.inventory, color: Colors.green[700]),
                    ),
                    title: Text(prod.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Stock: ${prod.stock}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${prod.precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _mostrarFormularioProducto(
                                  productoAEditar: prod, index: i),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[400]),
                          onPressed: () =>
                              _confirmarEliminarProducto(i, prod.nombre),
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
        onPressed: _intentarAbrirFormularioNuevoProducto, // Llama a la función refactorizada
      ),
      bottomNavigationBar: _anunciosService
          .obtenerBannerWidget(), // Usar la instancia
    );
  }
}