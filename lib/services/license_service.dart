import 'dart:convert';
import 'dart:io';
import 'dart:math'; // <--- NECESARIO PARA EL ALEATORIO
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseService {
  // 🔐 TU SECRETO DE ORO
  static const String _secretSalt = "Flguma36Quibtu41";

  // 1. Obtener ID del Dispositivo (MEJORADO)
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // A. Buscamos si ya tiene un "Tatuaje" (Sufijo único) guardado
    String? uniqueSuffix = prefs.getString('device_unique_suffix');

    // B. Si no tiene (es la primera vez), le creamos uno y lo guardamos
    if (uniqueSuffix == null) {
      // Generamos 6 caracteres aleatorios (Ej: "X9J2K1")
      uniqueSuffix = _generarCodigoAleatorio(6);
      await prefs.setString('device_unique_suffix', uniqueSuffix);
    }

    String baseId = "unknown";
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Usamos el ID de Android, o si falla, usamos el modelo
        baseId = androidInfo.id ?? "${androidInfo.brand}_${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        baseId = iosInfo.identifierForVendor ?? "ios_device";
      }
    } catch (e) {
      baseId = "error_device";
    }

    // C. Combinamos: Hardware + Tatuaje Único
    // Ej: "bf6193..._X9J2K1"
    // Esto garantiza 100% que sea único, incluso en teléfonos gemelos.
    return "${baseId}_$uniqueSuffix".toUpperCase();
  }

  // Función auxiliar para generar letras y números aleatorios
  String _generarCodigoAleatorio(int longitud) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        longitud,
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
    ));
  }

  // 2. Generar la Clave Esperada (Sin cambios, la matemática es la misma)
  String generateLicenseKey(String deviceId) {
    var bytes = utf8.encode(deviceId + _secretSalt);
    var digest = sha256.convert(bytes);
    String rawHash = digest.toString().toUpperCase();
    return "${rawHash.substring(0, 4)}-${rawHash.substring(4, 8)}-${rawHash.substring(8, 12)}";
  }

  // 3. Verificar Licencia (Sin cambios)
  Future<bool> activateLicense(String inputKey) async {
    String deviceId = await getDeviceId();
    String expectedKey = generateLicenseKey(deviceId);
    if (inputKey.trim() == expectedKey) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_licensed', true);
      return true;
    } else {
      return false;
    }
  }

  // 4. Chequear estado (Sin cambios)
  Future<bool> isAppLicensed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_licensed') ?? false;
  }
}