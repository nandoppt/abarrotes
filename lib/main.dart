import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
// TUS MODELOS Y PANTALLAS
import 'models/producto.dart';
import 'models/configuracion.dart';
import 'screens/home_screen.dart';
import 'screens/license_screen.dart';
import 'services/license_service.dart';
import 'services/anuncios_service.dart';

void main() async {
  // 1. Inicialización obligatoria del motor de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configurar formato de fechas
  await initializeDateFormatting('es', null);

  // 3. Inicializar Hive (Base de datos local)
  // Nota: initFlutter ya maneja el directorio, pero si quieres ser específico usa dir.path
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // 4. Registrar Adaptadores (ANTES de abrir las cajas)
  // Asegúrate de haber generado los archivos .g.dart
  // Solo registramos ProductoAdapter si no está registrado (aunque Hive suele manejar esto bien)
  Hive.registerAdapter(ConfiguracionAdapter());
  Hive.registerAdapter(ProductoAdapter());

  // 5. Abrir Cajas (Boxes)
  await Hive.openBox('configuracion'); // Caja genérica

  if (!Hive.isBoxOpen('configuracionBox')) {
    await Hive.openBox<Configuracion>('configuracionBox'); // Caja tipada
  }
  if (!Hive.isBoxOpen('productosBox')) {
    await Hive.openBox<Producto>('productosBox');
  }
  if (!Hive.isBoxOpen('ventasBox')) {
    await Hive.openBox('ventasBox');
  }

  // 6. Servicios de Anuncios y Compras
  AnunciosService().inicializarAnuncios();

  final config = RequestConfiguration(
    testDeviceIds: ['C9D0DE8127D83D064767B7705B4F9E5F'],
  );
  MobileAds.instance.updateRequestConfiguration(config);
  await MobileAds.instance.initialize();

  await Purchases.configure(
    PurchasesConfiguration("goog_umJXKUKcyiFxadHLRhKmUCSPHrH"),
  );

  // 7. SEGURIDAD: Verificar Licencia del Dispositivo
  final licenseService = LicenseService();
  bool isLicensed = await licenseService.isAppLicensed();

  // Si tiene licencia -> Home. Si no -> Pantalla de Bloqueo.
  Widget pantallaInicial = isLicensed ? HomeScreen() : LicenseScreen();

  // 8. Arrancar la App
  runApp(AbarrotesApp(startScreen: pantallaInicial));
}

class AbarrotesApp extends StatelessWidget {
  // Variable para recibir la pantalla inicial
  final Widget startScreen;

  // Constructor que obliga a recibir la pantalla
  const AbarrotesApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiendita',
      theme: ThemeData(primarySwatch: Colors.green),
      // Aquí se usa la variable que calculamos en el main
      home: startScreen,
      debugShowCheckedModeBanner: false,
      // Rutas opcionales para navegación posterior
      routes: {
        '/home': (context) => HomeScreen(),
        '/license': (context) => LicenseScreen(),
      },
    );
  }
}