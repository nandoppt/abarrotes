import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoProductos extends StatefulWidget {
  final Map<String, int> datos;

  const GraficoProductos({super.key, required this.datos});

  @override
  State<GraficoProductos> createState() => _GraficoProductosState();
}

class _GraficoProductosState extends State<GraficoProductos> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final top = widget.datos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = top.take(5).toList();
    final total = top5.fold<int>(0, (sum, e) => sum + e.value);

    return Column(
      children: [
        const Text('Top 5 productos más vendidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 280,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sections: List.generate(top5.length, (index) {
                final e = top5[index];
                final isTouched = index == touchedIndex;
                final double fontSize = isTouched ? 16 : 12;
                final double radius = isTouched ? 90 : 70;
                final porcentaje = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';

                return PieChartSectionData(
                  color: _getColor(index),
                  value: e.value.toDouble(),
                  title: '${e.key}\n$porcentaje%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
        ),
      ],
    );
  }

  Color _getColor(int index) {
    const colores = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    return colores[index % colores.length];
  }
}
