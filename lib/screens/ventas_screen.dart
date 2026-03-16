import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/producto.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final Box<Producto> _productosBox = Hive.box<Producto>('productosBox');
  final Box _ventasBox = Hive.box('ventasBox');

  List<Map<String, dynamic>> _carrito = [];
  double _totalCarrito = 0;

  void _agregarAlCarrito(Producto producto, int cantidad) {
    setState(() {
      final index = _carrito.indexWhere((item) => item['producto'].nombre == producto.nombre);
      if (index != -1) {
        // Ya existe, solo suma la cantidad y actualiza total
        _carrito[index]['cantidad'] += cantidad;
        _carrito[index]['total'] = producto.precio * _carrito[index]['cantidad'];
      } else {
        // Es nuevo en el carrito
        _carrito.add({
          'producto': producto,
          'cantidad': cantidad,
          'total': producto.precio * cantidad,
        });
      }
      _totalCarrito = _carrito.fold(0.0, (sum, item) => sum + item['total']);
    });
  }



  void _venderProducto(Producto producto) {
    final TextEditingController _cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vender: ${producto.nombre}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21, color: Colors.green[400])),
              const SizedBox(height: 14),
              Text('Stock disponible: ${producto.stock}', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              TextField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad a vender',
                  prefixIcon: Icon(Icons.numbers, color: Colors.green[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.green.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.green.shade300, width: 2),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final cantidad = int.tryParse(_cantidadController.text);

                      if (cantidad == null || cantidad <= 0) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Cantidad inválida'),
                            content: const Text('Debes ingresar una cantidad mayor a cero.'),
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

                      if (cantidad > producto.stock) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Stock insuficiente'),
                            content: Text('Solo hay ${producto.stock} '
                                'unidades disponibles. Verifique el stock.'),
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
                      // Si pasa las validaciones, continúa
                      _agregarAlCarrito(producto, cantidad);
                      Navigator.pop(context);
                    },
                    child: const Text('Agregar'),
                  ),


                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarCarrito(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Resumen de la venta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._carrito.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final prod = item['producto'] as Producto;
                  int cant = item['cantidad'];
                  final total = prod.precio * cant;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primera línea: nombre y total
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                prod.nombre,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Segunda línea: botones de cantidad y eliminar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setStateDialog(() {
                                  if (cant > 1) {
                                    _carrito[i]['cantidad'] = cant - 1;
                                    _carrito[i]['total'] = prod.precio * (cant - 1);
                                  } else {
                                    _carrito.removeAt(i);
                                  }
                                  _totalCarrito = _carrito.fold(0.0, (sum, item) => sum + item['total']);
                                });
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('$cant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setStateDialog(() {
                                  _carrito[i]['cantidad'] = cant + 1;
                                  _carrito[i]['total'] = prod.precio * (cant + 1);
                                  _totalCarrito = _carrito.fold(0.0, (sum, item) => sum + item['total']);
                                });
                              },
                            ),
                            // Spacer para separar del eliminar
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 21),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setStateDialog(() {
                                  _carrito.removeAt(i);
                                  _totalCarrito = _carrito.fold(0.0, (sum, item) => sum + item['total']);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'TOTAL: \$${_totalCarrito.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _carrito.isEmpty
                  ? null
                  : () {
                // Validar stock antes de procesar
                for (var item in _carrito) {
                  final prod = item['producto'] as Producto;
                  final cant = item['cantidad'] as int;
                  if (cant > prod.stock) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Stock insuficiente'),
                        content: Text('El producto "${prod.nombre}" solo tiene ${prod.stock} unidades disponibles.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    return; // No procesa la venta
                  }
                }

                // Si todo está bien, descontar stock y guardar
                for (var item in _carrito) {
                  final prod = item['producto'] as Producto;
                  final cant = item['cantidad'] as int;
                  prod.stock -= cant;
                  prod.save();
                }
                _ventasBox.add({
                  'fecha': DateTime.now().toIso8601String(),
                  'productos': _carrito.map((item) => {
                    'nombre': item['producto'].nombre,
                    'cantidad': item['cantidad'],
                    'precio': item['producto'].precio,
                    'total': item['total'],
                  }).toList(),
                  'total': _totalCarrito
                });
                setState(() {
                  _carrito.clear();
                  _totalCarrito = 0;
                });

                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Venta realizada'),
                    content: const Text('¡La venta se ha registrado correctamente!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Confirmar Venta'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final productos = _productosBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Registrar Ventas',
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
        child: productos.isEmpty
            ? Center(child: Text('No hay productos registrados', style: TextStyle(color: Colors.grey[600])))
            : ListView.builder(
          itemCount: productos.length,
          itemBuilder: (context, i) {
            final producto = productos[i];
            final stockBajo = producto.stock < 5;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: stockBajo ? Colors.red[100] : Colors.green[100],
                  child: Icon(Icons.shopping_cart, color: stockBajo ? Colors.red : Colors.green[700]),
                ),
                title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock: ${producto.stock}',
                      style: TextStyle(color: stockBajo ? Colors.red : Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.point_of_sale, size: 17),
                            label: const Text('Vender', style: TextStyle(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              minimumSize: const Size(80, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                            ),
                            onPressed: producto.stock > 0
                                ? () => _venderProducto(producto)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
              ),

            );

          },

        )
        ,
      ),
      floatingActionButton: _carrito.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => _mostrarCarrito(context),
        label: const Text('Ver Venta'),
        icon: const Icon(Icons.shopping_cart_checkout),
        backgroundColor: Colors.green[400],
      )
          : null,
    );

  }

}
