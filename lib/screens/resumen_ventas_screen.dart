import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'ventas_por_periodo_screen.dart';

class ResumenVentasScreen extends StatelessWidget {
  final String tipo; // 'semana' o 'mes'

  const ResumenVentasScreen({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final Box ventasBox = Hive.box('ventasBox');
    final ventas = ventasBox.values.toList().cast<Map>();

    final Map<String, double> resumen = {};

    for (var venta in ventas) {
      final fecha = DateTime.tryParse(venta['fecha']) ?? DateTime(2000);

      String clave;
      if (tipo == 'semana') {
        final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
        clave = DateFormat('yyyy-MM-dd').format(inicioSemana);
      } else {
        clave = DateFormat('yyyy-MM').format(fecha);
      }

      final total = (venta['total'] ?? 0.0) as num;
      resumen[clave] = (resumen[clave] ?? 0.0) + total.toDouble();
    }

    final clavesOrdenadas = resumen.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 2,
        centerTitle: true,
        title: Text('Ingresos por ${tipo == 'semana' ? "semana" : "mes"}',
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
        child: clavesOrdenadas.isEmpty
            ? Center(child: Text('No hay ventas registradas', style: TextStyle(color: Colors.grey[600])))
            : ListView.builder(
          itemCount: clavesOrdenadas.length,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          itemBuilder: (context, index) {
            final clave = clavesOrdenadas[index];
            final total = resumen[clave]!;
            final label = tipo == 'semana'
                ? 'Semana del ${DateFormat('dd/MM/yyyy').format(DateTime.parse(clave))}'
                : 'Mes ${DateFormat('MMMM yyyy', 'es').format(DateTime.parse('$clave-01'))}';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 7),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: tipo == 'semana' ? Colors.orange[100] : Colors.teal[100],
                  child: Icon(
                    tipo == 'semana' ? Icons.calendar_view_week : Icons.calendar_month,
                    color: tipo == 'semana' ? Colors.orange[700] : Colors.teal[700],
                    size: 29,
                  ),
                ),
                title: Text(
                  label,
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
                      builder: (_) => VentasPorPeriodoScreen(clave: clave, tipo: tipo),
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
