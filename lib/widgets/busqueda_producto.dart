import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/producto.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BusquedaProductosWidget extends StatefulWidget {
  final bool modoVenta; // true = ventas (grid), false = inventario
  final Function(Producto)? onAgregar;

  const BusquedaProductosWidget({
    super.key,
    this.modoVenta = false,
    this.onAgregar, // 👈 FALTABA ESTO
  });

  @override
  State<BusquedaProductosWidget> createState() => _BusquedaProductosWidgetState();
}

class _BusquedaProductosWidgetState extends State<BusquedaProductosWidget> {
  final Box<Producto> _productosBox = Hive.box<Producto>('productosBox');

  String searchQuery = '';
  bool filtroStockCritico = false;
  bool filtroEconomico = false;
  bool filtroPremium = false;
  bool isGrid = false;

  Timer? _debounce;

  List<Producto> _resultados = [];

  @override
  void initState() {
    super.initState();
    _resultados = _productosBox.values.toList();
  }

  // 🔎 BUSCADOR CON DEBOUNCE
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query;
        _filtrar();
      });
    });
  }

  // 🧠 FILTRO CENTRAL
  void _filtrar() {
    final productos = _productosBox.values.toList();

    _resultados = productos.where((p) {
      final matchBusqueda =
      p.nombre.toLowerCase().contains(searchQuery.toLowerCase());

      final matchStock =
          !filtroStockCritico || p.stock < 5;

      final matchPrecio =
          (!filtroEconomico && !filtroPremium) ||
              (filtroEconomico && p.precio <= 5) ||
              (filtroPremium && p.precio > 5);

      return matchBusqueda && matchStock && matchPrecio;
    }).toList();
  }

  // 🎨 COLOR DE STOCK
  Color getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }

  // 🔥 TEXTO CON HIGHLIGHT
  Widget highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) return Text(text);

    final end = start + query.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, start), style: const TextStyle(color: Colors.black)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(end), style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  // 🖼️ IMAGEN SEGURA
  Widget buildImagen(String? path) {
    if (path != null && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return const Icon(Icons.image_not_supported);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _productosBox.listenable(),
      builder: (context, Box<Producto> box, _) {

        final productos = box.values.toList();

        // 🔥 Siempre recalcula (esto evita bugs)
        _resultados = productos.where((p) {
          final matchBusqueda =
          p.nombre.toLowerCase().contains(searchQuery.toLowerCase());

          final matchStock =
              !filtroStockCritico || p.stock < 5;

          final matchPrecio =
              (!filtroEconomico && !filtroPremium) ||
                  (filtroEconomico && p.precio <= 5) ||
                  (filtroPremium && p.precio > 5);

          return matchBusqueda && matchStock && matchPrecio;
        }).toList();

        return Column(
          children: [

            /// 🔎 BUSCADOR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: 'Buscar producto...',
                  border: InputBorder.none,
                ),
              ),
            ),

            /// 🎛️ FILTROS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Stock Crítico', filtroStockCritico, () {
                    setState(() {
                      filtroStockCritico = !filtroStockCritico;
                    });
                  }),
                  _chip('Económico', filtroEconomico, () {
                    setState(() {
                      filtroEconomico = !filtroEconomico;
                      filtroPremium = false;
                    });
                  }),
                  /// 🔄 TOGGLE VISTA
                  IconButton(
                    icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
                    onPressed: () {
                      setState(() => isGrid = !isGrid);
                    },
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// 📊 RESULTADOS
            Expanded(
              child: widget.modoVenta
                  ? _buildGrid() // en ventas siempre grid
                  : (isGrid ? _buildGrid() : _buildLista()),
            ),
          ],
        );
      },
    );
  }

  // 🧾 LISTA INVENTARIO
  Widget _buildLista() {
    return ListView.builder(
      itemCount: _resultados.length,
      itemBuilder: (_, i) {
        final p = _resultados[i];

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 45,
              height: 45,
              child: buildImagen(p.imagenPath),
            ),
          ),
          title: highlightText(p.nombre, searchQuery),
          subtitle: Text(
            'Stock: ${p.stock}',
            style: TextStyle(color: getStockColor(p.stock)),
          ),
          trailing: Text('\$${p.precio.toStringAsFixed(2)}'),
        );
      },
    );
  }

  // 🧊 GRID VENTAS
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _resultados.length,
      itemBuilder: (_, i) {
        final p = _resultados[i];

        return GestureDetector(
          onTap: () {
            if (widget.onAgregar != null) {
              widget.onAgregar!(p);
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: buildImagen(p.imagenPath),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      highlightText(p.nombre, searchQuery),
                      const SizedBox(height: 5),
                      Text('\$${p.precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'Stock: ${p.stock}',
                        style: TextStyle(
                          color: getStockColor(p.stock),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎛️ CHIP
  Widget _chip(String text, bool activo, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(text),
        selected: activo,
        onSelected: (_) => onTap(),
        selectedColor: Colors.green[300],
      ),
    );
  }
}