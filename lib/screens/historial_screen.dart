import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final Box ventasBox = Hive.box('ventasBox');
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Historial',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: "Filtrar por fechas",
            onPressed: () async {
              final rango = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: (_fechaInicio != null && _fechaFin != null)
                    ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
                    : null,
              );
              if (rango != null) {
                setState(() {
                  _fechaInicio = rango.start;
                  _fechaFin = rango.end;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: "Quitar filtro",
            onPressed: () {
              setState(() {
                _fechaInicio = null;
                _fechaFin = null;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ValueListenableBuilder(
          valueListenable: ventasBox.listenable(),
          builder: (context, Box box, _) {
            final ventasOriginal = box.values.toList().reversed.toList();

            // Filtro por rango de fechas
            final ventas = (_fechaInicio != null && _fechaFin != null)
                ? ventasOriginal.where((venta) {
              final rawFecha = venta['fecha'];
              if (rawFecha == null) return false;
              final fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();

              // Ajusta los límites para incluir TODAS las ventas de la fecha de inicio y fin
              final desde = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day, 0, 0, 0);
              final hasta = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day, 23, 59, 59);

              return !fecha.isBefore(desde) && !fecha.isAfter(hasta);
            }).toList()
                : ventasOriginal;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_fechaInicio != null && _fechaFin != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Filtro: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                          ' - ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}',
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                    ),
                  ),
                Expanded(
                  child: ventas.isEmpty
                      ? Center(
                    child: Text(
                      'No hay ventas en el rango seleccionado',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                      : ListView.builder(
                    itemCount: ventas.length,
                    itemBuilder: (context, i) {
                      final venta = ventas[i];
                      final fecha = DateTime.tryParse(venta['fecha'] ?? '') ?? DateTime.now();
                      final productos = venta['productos'] as List<dynamic>? ?? [];
                      final total = venta['total'] ?? 0.0;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.receipt_long, color: Colors.green[700]),
                          ),
                          title: Text(
                            'Venta del ${fecha.day}/${fecha.month}/${fecha.year}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Total: \$${total.toStringAsFixed(2)}\n'
                                'Hora: ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14, color: Colors.teal),
                          ),
                          children: productos
                              .map((p) => ListTile(
                            title: Text(p['nombre']),
                            subtitle: Text('Cantidad: ${p['cantidad']} x \$${p['precio'].toStringAsFixed(2)}'),
                            trailing: Text('\$${p['total'].toStringAsFixed(2)}'),
                          ))
                              .toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
