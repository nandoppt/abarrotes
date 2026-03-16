import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:abarrotes/models/configuracion.dart';

class VentasPorDiaScreen extends StatelessWidget {
  final String fechaClave;

  const VentasPorDiaScreen({super.key, required this.fechaClave});

  @override
  Widget build(BuildContext context) {
    final Box ventasBox = Hive.box('ventasBox');
    final ventas = ventasBox.values.toList().cast<Map>();
    final List<Map> ventasFiltradas = [];
    double totalDia = 0;

    for (var venta in ventas) {
      final fecha = DateTime.tryParse(venta['fecha']) ?? DateTime(2000);
      final clave = DateFormat('yyyy-MM-dd').format(fecha);
      if (clave == fechaClave) {
        ventasFiltradas.add(venta);
        totalDia += (venta['total'] ?? 0.0) as double;
      }
    }

    final fechaFormateada = DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaClave));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 2,
        centerTitle: true,
        title: Text('Ventas - $fechaFormateada',
          style: TextStyle(
          fontSize: 24,            // Tamaño de fuente más grande
          fontWeight: FontWeight.bold,
          color: Colors.white,     // Color del texto
          letterSpacing: 1.1,      // Espaciado entre letras (opcional)
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // --- Resumen rápido arriba ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total ventas:', style: TextStyle(color: Colors.black54)),
                          Text('${ventasFiltradas.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Recaudado:', style: TextStyle(color: Colors.black54)),
                          Text('\$${totalDia.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // --- Lista de ventas en cards ---
            Expanded(
              child: ventasFiltradas.isEmpty
                  ? Center(child: Text('No hay ventas registradas para este día', style: TextStyle(color: Colors.grey[400])))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                itemCount: ventasFiltradas.length,
                  itemBuilder: (context, i) {
                    final venta = ventas[i];

                    // Si es una venta agrupada (nueva estructura)
                    final productos = venta['productos'] as List<dynamic>?;

                    if (productos != null && productos.isNotEmpty) {
                      if (productos.length == 1) {
                        final prod = productos[0];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange[100],
                            child: Icon(Icons.shopping_bag, color: Colors.orange[700]),
                          ),
                          title: Text('${prod['nombre'] ?? 'Producto'} x \$${prod['precio']?.toStringAsFixed(2) ?? '0.00'}'),
                          subtitle: Text('Cantidad: ${prod['cantidad']}'),
                          trailing: Text('\$${prod['total']?.toStringAsFixed(2) ?? '0.00'}'),
                        );
                      }
                      else {
                        // Si son varios productos en una sola venta (puedes mostrar solo el total y el número de ítems)
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange[100],
                            child: Icon(Icons.shopping_bag, color: Colors.orange[700]),
                          ),
                          title: Text('Venta múltiple (${productos.length} ítems)'),
                          subtitle: Text('Productos: ${productos.map((p) => p['nombre']).join(", ")}'),
                          trailing: Text('\$${venta['total']?.toStringAsFixed(2) ?? '0.00'}'),
                        );
                      }
                    } else {
                      // Compatibilidad con ventas antiguas, si existen
                      final nombre = venta['nombre'] ?? 'Producto';
                      final cantidad = venta['cantidad'] ?? 0;
                      final precio = venta['precio'] ?? 0.0;
                      final total = venta['total'] ?? 0.0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Icon(Icons.shopping_bag, color: Colors.orange[700]),
                        ),
                        title: Text('$nombre x \$${precio.toStringAsFixed(2)}'),
                        subtitle: Text('Cantidad: $cantidad'),
                        trailing: Text('\$${total.toStringAsFixed(2)}'),
                      );
                    }
                  }

              ),
            ),
            // --- Botones de exportar ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportarExcel(context, ventasFiltradas, fechaFormateada),
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Exportar a Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue[200],
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _generarPdf(context, ventasFiltradas, fechaFormateada),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar a PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange[200],
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _exportarExcel(BuildContext context, List<Map> ventas, String fechaFormateada) async {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Ventas_$fechaFormateada'];

    // Encabezados de la tabla
    sheet.appendRow(['Producto', 'Cantidad', 'Precio Unitario', 'Total']);

    // Procesa cada venta (agrupada o antigua)
    for (final venta in ventas) {
      final productos = venta['productos'] as List<dynamic>?;
      if (productos != null && productos.isNotEmpty) {
        // Venta agrupada: recorre todos los productos
        for (final prod in productos) {
          final nombre = prod['nombre']?.toString() ?? 'Producto';
          final cantidad = prod['cantidad']?.toString() ?? '0';
          final precio = prod['precio'] ?? 0.0;
          final total = prod['total'] ?? 0.0;
          sheet.appendRow([
            nombre,
            cantidad,
            (precio is double ? precio : double.tryParse('$precio') ?? 0.0),
            (total is double ? total : double.tryParse('$total') ?? 0.0),
          ]);
        }
      } else {
        // Venta antigua: solo un producto
        final nombre = venta['nombre']?.toString() ?? 'Producto';
        final cantidad = venta['cantidad']?.toString() ?? '0';
        final precio = venta['precioUnitario'] ?? venta['precio'] ?? 0.0;
        final total = venta['total'] ?? 0.0;
        sheet.appendRow([
          nombre,
          cantidad,
          (precio is double ? precio : double.tryParse('$precio') ?? 0.0),
          (total is double ? total : double.tryParse('$total') ?? 0.0),
        ]);
      }
    }

    final List<int>? rawBytes = excel.encode();
    if (rawBytes == null) return;
    final Uint8List bytes = Uint8List.fromList(rawBytes);
    final String titulo = 'Ventas_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
    final configBox = Hive.box<Configuracion>('configuracionBox');
    final config = configBox.get('actual');

    Directory dir;
    if (config != null && config.directorioDescarga != null && Directory(config.directorioDescarga!).existsSync()) {
      dir = Directory(config.directorioDescarga!);
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final File file = File('${dir.path}/$titulo.xlsx');
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archivo Excel guardado en: ${file.path}')),
    );
  }


  Future<void> _generarPdf(BuildContext context, List<Map> ventas, String titulo) async {
    final pdf = pw.Document();

    // Obtener configuración
    final configBox = Hive.box<Configuracion>('configuracionBox');
    final config = configBox.get('actual');

    pw.Widget encabezado = pw.SizedBox();

    if (config != null) {
      final List<pw.Widget> headerChildren = [];

      if (config.logoPath != null && File(config.logoPath!).existsSync()) {
        final imageBytes = File(config.logoPath!).readAsBytesSync();
        final logo = pw.MemoryImage(imageBytes);

        headerChildren.add(
          pw.Image(logo, width: 80, height: 80),
        );
      }

      headerChildren.add(
        pw.SizedBox(width: 12),
      );

      headerChildren.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(config.nombreNegocio, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Tel: ${config.telefono}'),
            pw.Text('Dirección: ${config.direccion}'),
            pw.Text('Fecha de emisión: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
          ],
        ),
      );

      encabezado = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: headerChildren,
      );
    }

    // BLOQUE: Construcción correcta de la tabla y suma de total
    final List<List<String>> filasTabla = [];
    double totalGeneral = 0.0;

    for (final venta in ventas) {
      final productos = venta['productos'] as List<dynamic>?;
      if (productos != null && productos.isNotEmpty) {
        // Venta agrupada: cada producto una fila
        for (final prod in productos) {
          final nombre = prod['nombre']?.toString() ?? 'Producto';
          final cantidad = prod['cantidad']?.toString() ?? '0';
          final precio = prod['precio'] ?? 0.0;
          final total = prod['total'] ?? 0.0;
          filasTabla.add([
            nombre,
            cantidad,
            '\$${(precio is double ? precio : double.tryParse('$precio') ?? 0.0).toStringAsFixed(2)}',
            '\$${(total is double ? total : double.tryParse('$total') ?? 0.0).toStringAsFixed(2)}',
          ]);
          totalGeneral += total is double ? total : double.tryParse('$total') ?? 0.0;
        }
      } else {
        // Venta antigua: un producto por registro
        final nombre = venta['nombre']?.toString() ?? 'Producto';
        final cantidad = venta['cantidad']?.toString() ?? '0';
        final precio = venta['precioUnitario'] ?? venta['precio'] ?? 0.0;
        final total = venta['total'] ?? 0.0;
        filasTabla.add([
          nombre,
          cantidad,
          '\$${(precio is double ? precio : double.tryParse('$precio') ?? 0.0).toStringAsFixed(2)}',
          '\$${(total is double ? total : double.tryParse('$total') ?? 0.0).toStringAsFixed(2)}',
        ]);
        totalGeneral += total is double ? total : double.tryParse('$total') ?? 0.0;
      }
    }

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              encabezado,
              pw.SizedBox(height: 20),
              pw.Text(titulo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Producto', 'Cantidad', 'Precio Unitario', 'Total'],
                data: filasTabla,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total: \$${totalGeneral.toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }




}
