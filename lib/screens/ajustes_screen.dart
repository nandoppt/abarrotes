import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../models/configuracion.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:file_selector/file_selector.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert';
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
  State<AjustesScreen> createState() => _AjustesScreenState();}

class _AjustesScreenState extends State<AjustesScreen> {
  final _nombreController = TextEditingController();
  final _ivaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _directorioController = TextEditingController();
  final _bienvenidaController = TextEditingController();

  final Box<Configuracion> _configBox = Hive.box<Configuracion>('configuracionBox');
  File? _logo;


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
  Future<void> _realizarBackup() async {
    final config = _configBox.get('actual');
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay configuración para respaldar')),
      );
      return;
    }

    final archive = Archive();

    // Agregar configuración como JSON simple
    final configJson = '''
    {
      "nombreNegocio": "${config.nombreNegocio}",
       "iva": ${config.iva},
        "telefono": "${config.telefono}",
          "direccion": "${config.direccion}",
              "directorioDescarga": "${config.directorioDescarga ?? ''}"
    }''';
    archive.addFile(ArchiveFile.string('configuracion.json', configJson));

    // Agregar logo si existe
    if (config.logoPath != null && File(config.logoPath!).existsSync()) {
      final logoFile = File(config.logoPath!);
      final logoBytes = logoFile.readAsBytesSync();
      archive.addFile(ArchiveFile('logo.png', logoBytes.length, logoBytes));
    }

    // Agregar archivos PDF y Excel si existen en carpeta destino
    Directory dirDestino;
    if (config.directorioDescarga != null && Directory(config.directorioDescarga!).existsSync()) {
      dirDestino = Directory(config.directorioDescarga!);
    } else {
      dirDestino = await getApplicationDocumentsDirectory();
    }

    final List<FileSystemEntity> archivos = dirDestino.listSync();
    for (var file in archivos) {
      if (file is File && (file.path.endsWith('.pdf') || file.path.endsWith('.xlsx'))) {
        final bytes = file.readAsBytesSync();
        archive.addFile(ArchiveFile(p.basename(file.path), bytes.length, bytes));
      }
    }

    // Crear archivo ZIP
    final zipBytes = ZipEncoder().encode(archive);
    final backupFile = File(p.join(dirDestino.path, 'backup_abarrotes.zip'));
    await backupFile.writeAsBytes(zipBytes!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup guardado en: ${backupFile.path}')),
    );
  }

  Future<void> _restaurarBackup() async {
    // Selecciona el archivo ZIP con file_selector
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'zip',
      extensions: ['zip'],
    );
    final XFile? xfile = await openFile(acceptedTypeGroups: [typeGroup]);
    if (xfile == null) return;

    final zipFile = File(xfile.path);
    final bytes = await zipFile.readAsBytes(); // Usa async/await siempre que puedas
    final archive = ZipDecoder().decodeBytes(bytes);

    String? configJson;
    File? logoRecuperado;

    final dir = await getApplicationDocumentsDirectory();

    for (final file in archive) {
      final data = file.content as List<int>;

      if (file.name == 'configuracion.json') {
        configJson = utf8.decode(data);
      } else if (file.name == 'logo.png') {
        final logoFile = File('${dir.path}/logo_restaurado.png');
        await logoFile.writeAsBytes(data);
        logoRecuperado = logoFile;
      } else if (file.name.endsWith('.pdf') || file.name.endsWith('.xlsx')) {
        final destino = File('${dir.path}/${file.name}');
        await destino.writeAsBytes(data);
      }
    }

    if (configJson != null) {
      final decoded = jsonDecode(configJson);

      final nuevaConfig = Configuracion(
        nombreNegocio: decoded['nombreNegocio'] ?? '',
        iva: decoded['iva']?.toDouble() ?? 0,
        telefono: decoded['telefono'] ?? '',
        direccion: decoded['direccion'] ?? '',
        logoPath: logoRecuperado?.path,
        directorioDescarga: decoded['directorioDescarga'],
      );

      _configBox.put('actual', nuevaConfig);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restaurado correctamente')),
      );

      setState(() {
        _nombreController.text = nuevaConfig.nombreNegocio;
        _ivaController.text = nuevaConfig.iva.toString();
        _telefonoController.text = nuevaConfig.telefono;
        _direccionController.text = nuevaConfig.direccion;
        _directorioController.text = nuevaConfig.directorioDescarga ?? '';
        _logo = logoRecuperado;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup inválido: configuración no encontrada')),
      );
    }
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
        const SnackBar(content: Text('Ruta de descarga no válida')),
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
      const SnackBar(content: Text('Configuración guardada')),
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
              fontSize: 26,            // Tamaño de fuente más grande
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
                // CAMPOS DE CONFIGURACIÓN (modernos y bonitos)
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
                  label: 'Teléfono',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 15),
                _CampoTextoBonito(
                  controller: _direccionController,
                  label: 'Dirección',
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
