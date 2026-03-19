import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../models/configuracion.dart';
import '../models/producto.dart';
import '../services/backup_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class _CampoTextoBonito extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String label;
  final String? hint;
  final IconData icon;

  const _CampoTextoBonito({
    required this.controller,
    this.keyboardType,
    required this.label,
    this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.green[700]),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade300, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 12),
    );
  }
}


class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _nombreController = TextEditingController();
  final _ivaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _directorioController = TextEditingController();
  final _bienvenidaController = TextEditingController();

  Box<Configuracion> get _configBox => Hive.box<Configuracion>('configuracionBox');
  File? _logo;
  final BackupService _backupService = BackupService();


  @override
  void initState() {
    super.initState();
    final config = _configBox.get('actual');
    if (config != null) {
      _nombreController.text = config.nombreNegocio;
      _ivaController.text = config.iva.toString();
      _telefonoController.text = config.telefono;
      _direccionController.text = config.direccion;
      if (config.directorioDescarga != null) {
        _directorioController.text = config.directorioDescarga!;
      }
      if (config.logoPath != null) {
        _logo = File(config.logoPath!);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ivaController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _directorioController.dispose();
    _bienvenidaController.dispose();
    super.dispose();
  }

  Future<void> _realizarBackup() async {
    final config = _configBox.get('actual');
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay configuraciÃ³n para respaldar')),
      );
      return;
    }

    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecciona una carpeta para guardar el backup',
    );
    if (dirPath == null) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupFile = await _backupService.createBackup(
        sourceDocumentsDir: docsDir,
        destinationDir: Directory(dirPath),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup guardado en: ${backupFile.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error realizando backup: $e')),
      );
    }
  }

  Future<void> _restaurarBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecciona el archivo ZIP del backup',
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedPath = result.files.single.path;
    if (pickedPath == null) return;

    try {
      final zipFile = File(pickedPath);
      final docsDir = await getApplicationDocumentsDirectory();

      // Cerrar Hive para liberar locks antes de reemplazar archivos.
      await Hive.close();

      await _backupService.restoreBackup(
        zipFile: zipFile,
        targetDocumentsDir: docsDir,
      );

      await _reabrirHive(docsDir);
      await _repararRutasImagenes(docsDir);

      final config = _configBox.get('actual');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restaurado correctamente')),
      );

      setState(() {
        _nombreController.text = config?.nombreNegocio ?? '';
        _ivaController.text = (config?.iva ?? 0).toString();
        _telefonoController.text = config?.telefono ?? '';
        _direccionController.text = config?.direccion ?? '';
        _directorioController.text = config?.directorioDescarga ?? '';

        final logoPath = config?.logoPath;
        _logo = (logoPath != null && File(logoPath).existsSync()) ? File(logoPath) : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restaurando backup: $e')),
      );
    }
  }

  Future<void> _reabrirHive(Directory docsDir) async {
    Hive.init(docsDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductoAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ConfiguracionAdapter());
    }

    await Hive.openBox('configuracion');
    await Hive.openBox<Configuracion>('configuracionBox');
    await Hive.openBox<Producto>('productosBox');
    await Hive.openBox('ventasBox');
  }

  Future<void> _repararRutasImagenes(Directory docsDir) async {
    final config = _configBox.get('actual');
    if (config != null && config.logoPath != null) {
      final newLogo = _mapToDocumentsPath(docsDir, config.logoPath!);
      if (newLogo != null && newLogo != config.logoPath) {
        config.logoPath = newLogo;
        await config.save();
      }
    }

    final productosBox = Hive.box<Producto>('productosBox');
    for (final prod in productosBox.values) {
      final old = prod.imagenPath;
      if (old == null || old.isEmpty) continue;

      final newPath = _mapToProductsPath(docsDir, old) ?? _mapToDocumentsPath(docsDir, old);
      if (newPath != null && newPath != old) {
        prod.imagenPath = newPath;
        await prod.save();
      }
    }
  }

  String? _mapToDocumentsPath(Directory docsDir, String oldPath) {
    final name = p.basename(oldPath);
    final candidate = p.join(docsDir.path, name);
    return File(candidate).existsSync() ? candidate : null;
  }

  String? _mapToProductsPath(Directory docsDir, String oldPath) {
    final name = p.basename(oldPath);
    final candidate = p.join(docsDir.path, 'productos', name);
    return File(candidate).existsSync() ? candidate : null;
  }


  Future<void> _guardarConfiguracion() async {
    final nombre = _nombreController.text.trim();
    final iva = double.tryParse(_ivaController.text) ?? 0;
    final telefono = _telefonoController.text.trim();
    final direccion = _direccionController.text.trim();
    final ruta = _directorioController.text.trim();

    String? logoPath;
    if (_logo != null) {
      final dir = await getApplicationDocumentsDirectory();
      final logoFinal = File('${dir.path}/logo.png');
      await _logo!.copy(logoFinal.path);
      logoPath = logoFinal.path;
    }

    if (ruta.isNotEmpty && !Directory(ruta).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta de descarga no vÃ¡lida')),
      );
      return;
    }

    final config = Configuracion(
      nombreNegocio: nombre,
      iva: iva,
      telefono: telefono,
      direccion: direccion,
      logoPath: logoPath,
      directorioDescarga: ruta.isNotEmpty ? ruta : null,
    );

    _configBox.put('actual', config);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ConfiguraciÃ³n guardada')),
    );
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = "logo_${DateTime.now().millisecondsSinceEpoch}.png";
      final saved = await File(picked.path).copy('${appDir.path}/$fileName');
      setState(() {
        _logo = saved;
      });
      final config = _configBox.get('actual');
      if (config != null) {
        config.logoPath = saved.path;
        config.save();
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          elevation: 2,
          centerTitle: true,
          title: const Text(
            'Ajustes',
            style: TextStyle(
              fontSize: 26,            // TamaÃ±o de fuente mÃ¡s grande
              fontWeight: FontWeight.bold,
              color: Colors.white,     // Color del texto
              letterSpacing: 1.1,      // Espaciado entre letras (opcional)
            ),
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 7,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO + NOMBRE
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(38),
                      onTap: _seleccionarLogo,
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.green[50],
                        backgroundImage: _logo != null ? FileImage(_logo!) : null,
                        child: _logo == null
                            ? Icon(Icons.store_mall_directory_rounded, size: 40, color: Colors.green[700])
                            : null,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: 'Nombre de la tienda',
                            ),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          // Si quieres incluir mensaje de bienvenida, descomenta:
                          // TextField(
                          //   controller: _bienvenidaController,
                          //   decoration: const InputDecoration(
                          //     border: InputBorder.none,
                          //     labelText: 'Mensaje de bienvenida',
                          //   ),
                          //   style: const TextStyle(fontSize: 15, color: Colors.black54),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // CAMPOS DE CONFIGURACIÃ“N (modernos y bonitos)
               /* _CampoTextoBonito(
                  controller: _ivaController,
                  keyboardType: TextInputType.number,
                  label: 'IVA (%)',
                  icon: Icons.percent,
                ),*/
                const SizedBox(height: 15),
                _CampoTextoBonito(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  label: 'TelÃ©fono',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 15),
                _CampoTextoBonito(
                  controller: _direccionController,
                  label: 'DirecciÃ³n',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 15),
                _CampoTextoBonito(
                  controller: _directorioController,
                  label: 'Ruta de descarga (opcional)',
                  hint: '/storage/emulated/0/Download',
                  icon: Icons.folder,
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: _realizarBackup,
                  icon: const Icon(Icons.backup, size: 22),
                  label: const Text('Realizar Backup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _restaurarBackup,
                  icon: const Icon(Icons.restore, size: 22),
                  label: const Text('Restaurar Backup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: _guardarConfiguracion,
                  icon: const Icon(Icons.save, size: 22),
                  label: const Text('Guardar Cambios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }

}
