import 'package:flutter/material.dart';
import 'package:pro_tocol/entity/GeneralConfig.dart';
import 'package:pro_tocol/entity/SSHService.dart';

class SSHOrchestrator extends ChangeNotifier {
  // CRITERIO 2: Manejar un mapa (Map) de conexiones activas para múltiples terminales.
  // Usaremos de llave un String con el formato "usuario@ip:puerto"
  final Map<String, SSHService> activeConnections = {};

  // CRITERIO 3: Informar a la vista si la conexión fue exitosa o falló.
  // Retornamos un String con el mensaje de error, o null si todo salió perfecto.
  Future<String?> connect(GeneralConfig config) async {
    // CRITERIO 1: Validar que los campos de IP y Usuario no estén vacíos antes de conectar.
    if (config.host.trim().isEmpty) {
      return "Error: La dirección IP (Host) no puede estar vacía.";
    }
    if (config.username.trim().isEmpty) {
      return "Error: El nombre de usuario no puede estar vacío.";
    }

    // Creamos un identificador único para esta conexión en el Map
    String connectionKey = _generateKey(config);

    if (activeConnections.containsKey(connectionKey) && activeConnections[connectionKey]!.isConnected) {
      return "Ya existe una conexión activa con este servidor.";
    }

    SSHService newConnection = SSHService();
    
    try {
      // Intentamos conectar
      bool success = await newConnection.connect(config);
      
      if (success) {
        // Si conecta, lo guardamos en nuestro mapa de sesiones paralelas
        activeConnections[connectionKey] = newConnection;
        notifyListeners();
        return null; // Retornamos null indicando que NO hubo errores (Éxito)
      } else {
        return "Fallo de autenticación: Verifica tu contraseña o llave SSH.";
      }
    } catch (e) {
      return "Error crítico al conectar: ${e.toString()}";
    }
  }

  /// Método para cerrar una conexión específica
  void disconnect(GeneralConfig config) {
    String key = _generateKey(config);
    if (activeConnections.containsKey(key)) {
      activeConnections[key]!.disconnect();
      activeConnections.remove(key);
      notifyListeners();
    }
  }

  /// Utilidad interna para generar la llave del Map
  String _generateKey(GeneralConfig config) {
    return "${config.username}@${config.host}:${config.port}";
  }
}