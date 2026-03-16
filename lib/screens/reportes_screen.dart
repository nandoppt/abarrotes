import 'package:flutter/material.dart';
import 'resumen_ventas_screen.dart';
import 'historial_ingresos_screen.dart';
import '/services/anuncios_service.dart';
class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardItems = [
      {
        'label': 'Resumen por Día',
        'icon': Icons.date_range,
        'color': Colors.teal[200],
        'onTap': () {
          AnunciosService().mostrarInterstitial();
          Future.delayed(const Duration(milliseconds: 800), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistorialIngresosScreen()),
            );
          });
        },

      },
      {
        'label': 'Resumen Semanal',
        'icon': Icons.calendar_view_week,
        'color': Colors.teal[200],
        'onTap': () {
          AnunciosService().mostrarInterstitial();
          Future.delayed(const Duration(milliseconds: 800), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResumenVentasScreen(tipo: 'semana')),
            );
          });
        },
      },
      {
        'label': 'Resumen Mensual',
        'icon': Icons.calendar_month,
        'color': Colors.teal[200],
        'onTap': () {
          AnunciosService().mostrarInterstitial();
          Future.delayed(const Duration(milliseconds: 800), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResumenVentasScreen(tipo: 'mes')),
            );
          });
        },

      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 2,
        centerTitle: true,
        title: const Text('Reportes',
          style: TextStyle(
            fontSize: 26,            // Tamaño de fuente más grande
            fontWeight: FontWeight.bold,
            color: Colors.white,     // Color del texto
            letterSpacing: 1.1,      // Espaciado entre letras (opcional)
          ),
        ),
      ),
      body: Container(
        color: Colors.white, // Color sólido, puedes cambiarlo por cualquier otro
        child: Center(
          child: GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            mainAxisSpacing: 22,
            childAspectRatio: 2.8,
            children: cardItems.map((item) {
              return GestureDetector(
                onTap: item['onTap'] as VoidCallback,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 7,
                  color: (item['color'] as Color),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 34),
                        radius: 28,
                      ),
                      const SizedBox(width: 26),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

}