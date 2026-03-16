import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'ventas_por_dia_screen.dart';

class HistorialIngresosScreen extends StatelessWidget {
  const HistorialIngresosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box ventasBox = Hive.box('ventasBox');
    final ventas = ventasBox.values.toList().cast<Map>();

    final Map<String, double> ingresosPorDia = {};

    for (var venta in ventas) {
      final fecha = DateTime.tryParse(venta['fecha']) ?? DateTime(2000);
      final fechaClave = DateFormat('yyyy-MM-dd').format(fecha);
      final total = (venta['total'] ?? 0.0) as num;

      ingresosPorDia[fechaClave] = (ingresosPorDia[fechaClave] ?? 0.0) + total.toDouble();
    }

    final fechasOrdenadas = ingresosPorDia.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Más reciente primero

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 2,
        centerTitle: true,
        title: const Text('Ingresos por día',
          style: TextStyle(
            fontSize: 26,            // Tamaño de fuente más grande
            fontWeight: FontWeight.bold,
            color: Colors.white,     // Color del texto
            letterSpacing: 1.1,      // Espaciado entre letras (opcional)
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: fechasOrdenadas.isEmpty
            ? Center(child: Text('No hay ingresos registrados', style: TextStyle(color: Colors.grey[600])))
            : ListView.builder(
          itemCount: fechasOrdenadas.length,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          itemBuilder: (context, index) {
            final fecha = fechasOrdenadas[index];
            final total = ingresosPorDia[fecha]!;
            final fechaFormateada = DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha));
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 7),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.calendar_today, color: Colors.blue[700], size: 28),
                ),
                title: Text(
                  fechaFormateada,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VentasPorDiaScreen(fechaClave: fecha),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

}
