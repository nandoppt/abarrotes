import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '/widgets/grafico_productos.dart';

// Actualización de _CardMiniEstadistica para soportar texto secundario
class _CardMiniEstadistica extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;
  final String? secondaryText;

  const _CardMiniEstadistica({
    required this.label,
    required this.valor,
    required this.color,
    this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      elevation: 4,
      color: color.withOpacity(0.20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('\$${valor.toStringAsFixed(2)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            if (secondaryText != null) ...[
              const SizedBox(height: 4),
              Text(secondaryText!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }
}

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box ventasBox = Hive.box('ventasBox');
    final ventas = ventasBox.values.toList().cast<Map>();

    // Métricas básicas
    double totalRecaudado = 0;
    int totalVentas = ventas.length;
    List<double> montosVentas = [];

    // Métricas por período
    double ventasHoy = 0;
    double ventasSemana = 0;
    double ventasMes = 0;
    int ventasCountHoy = 0;
    int ventasCountSemana = 0;
    int ventasCountMes = 0;

    // Métricas de productos
    final Map<String, int> productosVendidos = {};
    final Map<String, double> ingresosPorProducto = {};

    // Tendencias
    final Map<String, double> ventasPorDia = {};
    final Map<String, int> ventasCountPorDia = {};

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month);

    for (var venta in ventas) {
      final fecha = DateTime.tryParse(venta['fecha']) ?? DateTime(2000);
      final total = (venta['total'] as num?)?.toDouble() ?? 0.0;

      // Procesamiento para métricas básicas
      totalRecaudado += total;
      montosVentas.add(total);

      // Procesamiento por período
      if (fecha.isAfter(inicioHoy)) {
        ventasHoy += total;
        ventasCountHoy++;
      }
      if (fecha.isAfter(inicioSemana)) {
        ventasSemana += total;
        ventasCountSemana++;
      }
      if (fecha.isAfter(inicioMes)) {
        ventasMes += total;
        ventasCountMes++;
      }

      // Procesamiento de productos
      final productosVenta = venta['productos'] as List? ?? [];
      for (var producto in productosVenta) {
        final nombre = producto['nombre']?.toString() ?? 'Desconocido';
        final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 0;
        final precio = (producto['precio'] as num?)?.toDouble() ?? 0.0;

        productosVendidos[nombre] = (productosVendidos[nombre] ?? 0) + cantidad;
        ingresosPorProducto[nombre] = (ingresosPorProducto[nombre] ?? 0) + (cantidad * precio);
      }

      // Procesamiento para tendencias (por día)
      final dia = DateFormat('yyyy-MM-dd').format(fecha);
      ventasPorDia[dia] = (ventasPorDia[dia] ?? 0) + total;
      ventasCountPorDia[dia] = (ventasCountPorDia[dia] ?? 0) + 1;
    }
// Cálculo de métricas derivadas
    final promedioVenta = totalVentas > 0 ? totalRecaudado / totalVentas : 0;
    final promedioVentasHoy = ventasCountHoy > 0 ? ventasHoy / ventasCountHoy : 0;
    final promedioVentasSemana = ventasCountSemana > 0 ? ventasSemana / ventasCountSemana : 0;
    final promedioVentasMes = ventasCountMes > 0 ? ventasMes / ventasCountMes : 0;

    // Producto más vendido y más rentable
    String productoMasVendido = '-';
    int maxCantidad = 0;
    String productoMasRentable = '-';
    double maxIngresos = 0;

    productosVendidos.forEach((nombre, cantidad) {
      if (cantidad > maxCantidad) {
        productoMasVendido = nombre;
        maxCantidad = cantidad;
      }

      final ingresos = ingresosPorProducto[nombre] ?? 0;
      if (ingresos > maxIngresos) {
        productoMasRentable = nombre;
        maxIngresos = ingresos;
      }
    });

    // Tendencia: comparación con período anterior
    final ventasSemanaPasada = _calcularVentasPorPeriodo(
        ventas,
        inicioSemana.subtract(const Duration(days: 7)),
        inicioSemana
    );

    final diferenciaSemanal = ventasCountSemana > 0
        ? ((ventasSemana - ventasSemanaPasada) / ventasSemanaPasada) * 100
        : 0;

    return Scaffold(
     appBar: AppBar(
      backgroundColor: Colors.green[700],
      elevation: 2,
      centerTitle: true,
      title: const Text(
        'Estadisticas',
        style: TextStyle(
          fontSize: 26,            // Tamaño de fuente más grande
          fontWeight: FontWeight.bold,
          color: Colors.white,     // Color del texto
          letterSpacing: 1.1,      // Espaciado entre letras (opcional)
        ),
      ),
    ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              // --- Card resumen general ---
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                elevation: 6,
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen General', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total recaudado:', style: TextStyle(color: Colors.black54)),
                              Text('\$${totalRecaudado.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                              const SizedBox(height: 8),
                              Text('Promedio por venta: \$${promedioVenta.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Ventas totales:', style: TextStyle(color: Colors.black54)),
                              Text('$totalVentas',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
// Nuevo Card para Promedios
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Promedios de Ventas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem('Hoy', '\$${promedioVentasHoy.toStringAsFixed(2)}', Colors.green),
                          _buildMetricItem('Semana', '\$${promedioVentasSemana.toStringAsFixed(2)}', Colors.orange),
                          _buildMetricItem('Mes', '\$${promedioVentasMes.toStringAsFixed(2)}', Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // --- Cards rápidas (hoy / semana / mes) ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CardMiniEstadistica(
                      label: 'Hoy',
                      valor: ventasHoy,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    _CardMiniEstadistica(
                      label: 'Semana',
                      valor: ventasSemana,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    _CardMiniEstadistica(
                      label: 'Mes',
                      valor: ventasMes,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Productos destacados (nueva sección)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                  child: Column(
                    children: [
                      const Text('Productos Destacados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Más vendido:', style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 6),
                                Chip(
                                  label: Text(
                                    productoMasVendido,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.teal,
                                ),
                                Text('$maxCantidad unidades', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Más rentable:', style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 6),
                                Chip(
                                  label: Text(
                                    productoMasRentable,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.indigo,
                                ),
                                Text('\$${maxIngresos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // --- Gráfico de productos ---
              const Text(
                'Gráfico de productos vendidos:',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              GraficoProductos(datos: productosVendidos), // Tu widget de gráfico
            ],
          ),
        )

    );
  }
  double _calcularVentasPorPeriodo(List<Map> ventas, DateTime inicio, DateTime fin) {
    return ventas.fold(0.0, (sum, venta) {
      final fecha = DateTime.tryParse(venta['fecha']) ?? DateTime(2000);
      if (fecha.isAfter(inicio) && fecha.isBefore(fin)) {
        return sum + (venta['total'] as num).toDouble();
      }
      return sum;
    });
  }

  Widget _buildMetricItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
