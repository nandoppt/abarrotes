import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/configuracion.dart';
// Importa tus screens:
import 'productos_screen.dart';
import 'ventas_screen.dart';
import 'historial_screen.dart';
import 'estadisticas_screen.dart';
import 'reportes_screen.dart';
import 'ajustes_screen.dart';

// Si usas logoPath en tu modelo de Configuracion, lo toma de ahí
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key}); // Quitar el 'const' por uso de variables dinámicas

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Configuracion>('configuracionBox').                                                  listenable(),
      builder: (context, Box<Configuracion> configBox, _) {
        final config = configBox.get('actual');
        final nombreNegocio = config?.nombreNegocio ?? 'Nombre del negocio';
        final mensajeBienvenida = config?.bienvenida ?? '¡Bienvenido!';
        final logoPath = config?.logoPath;

        final menuItems = [
          _HomeMenuItem(
            label: 'Productos',
            icon: Icons.shopping_bag,
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductosScreen())),
          ),
          _HomeMenuItem(
            label: 'Registrar Venta',
            icon: Icons.point_of_sale,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentasScreen())),
          ),
          _HomeMenuItem(
            label: 'Historial',
            icon: Icons.history,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialScreen())),
          ),
          _HomeMenuItem(
            label: 'Estadísticas',
            icon: Icons.bar_chart,
            color: Colors.deepPurple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EstadisticasScreen())),
          ),
          _HomeMenuItem(
            label: 'Reportes',
            icon: Icons.description,
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportesScreen())),
          ),
          _HomeMenuItem(
            label: 'Ajustes',
            icon: Icons.settings,
            color: Colors.grey,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AjustesScreen())),
          ),
        ];

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90),
            child: AppBar(
              elevation: 0,
              backgroundColor: Colors.green[700],
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Si tienes un logo personalizado, lo muestra. Si no, muestra el ícono por defecto.
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: (logoPath != null && logoPath.isNotEmpty) ? FileImage(File(logoPath)) : null,
                        child: (logoPath == null || logoPath.isEmpty)
                            ? Icon(Icons.store_mall_directory_rounded, size: 36, color: Colors.green[700])
                            : null,
                      ),
                      const SizedBox(width: 18),
                      // Título y subtítulo dinámicos
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nombreNegocio,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            mensajeBienvenida,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                children: menuItems.map((item) => _HomeCard(item: item)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---- Define tus clases de menú y tarjetas, igual que antes ----

class _HomeMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _HomeMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _HomeCard extends StatelessWidget {
  final _HomeMenuItem item;
  const _HomeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: item.color.withOpacity(0.13),
                radius: 30,
                child: Icon(item.icon, size: 36, color: item.color),
              ),
              const SizedBox(height: 16),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
