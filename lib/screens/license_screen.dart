import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import '../services/license_service.dart';

class LicenseScreen extends StatefulWidget {
  @override
  _LicenseScreenState createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final LicenseService _licenseService = LicenseService();
  final TextEditingController _controller = TextEditingController();
  String _deviceId = "Cargando...";
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  void _loadDeviceId() async {
    String id = await _licenseService.getDeviceId();
    setState(() {
      _deviceId = id;
    });
  }

  void _activar() async {
    bool success = await _licenseService.activateLicense(_controller.text);
    if (success) {
      // Navegar al Home y borrar historial para que no pueda volver atrás
      Navigator.pushReplacementNamed(context, '/home'); // Ajusta tu ruta aquí
    } else {
      setState(() {
        _errorMessage = "Clave incorrecta. Verifica con el administrador.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text("ACTIVACIÓN REQUERIDA",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("Por favor envía este ID al administrador para recibir tu clave:",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),

            // ID DEL DISPOSITIVO
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. IMPORTANTE: Usamos Expanded para que si el ID es largo,
                  // baje a la siguiente línea en vez de romper la pantalla.
                  Expanded(
                    child: SelectableText(
                      _deviceId,
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 16, // Bajé un poco la fuente para que quepa mejor
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  // 2. El botón de copiar se queda a la derecha
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.white),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _deviceId));
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("ID copiado al portapapeles"),
                            backgroundColor: Colors.green,
                          )
                      );
                    },
                  )
                ],
              ),
            ),

            SizedBox(height: 30),
            TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: "Ingresa tu Clave de Activación",
                  labelStyle: TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black12
              ),
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_errorMessage, style: TextStyle(color: Colors.redAccent)),
              ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _activar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
              child: Text("ACTIVAR AHORA", style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}