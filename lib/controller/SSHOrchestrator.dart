
import 'package:flutter/material.dart';

import 'package:pro_tocol/model/entities/GeneralConfig.dart';
import 'package:pro_tocol/model/service/SSHService.dart';




class SSHOrchestrator extends ChangeNotifier {
  // Mapa de conexiones activas: La llave es "usuario@ip:puerto"
  final Map<String, SSHService> activeConnections = {};

  /// Obtiene el servicio activo para un servidor específico.
  /// Se usa en ServerScreen para acceder a terminal, métricas y SFTP.
  SSHService? getService(String connectionInfo) {
    try {
      // Buscamos por "user@host" o simplemente por "host"
      return activeConnections.values.firstWhere(
              (service) => "${service.config?.username}@${service.config?.host}" == connectionInfo ||
              service.config?.host == connectionInfo
      );
    } catch (e) {
      return null;
    }
  }

  /// Inicia la conexión física usando el SSHService.
  Future<String?> connect(GeneralConfig config) async {
    // 1. Validación de campos (Criterio de aceptación)
    if (config.host.trim().isEmpty) return "Error: La IP/Host es obligatoria.";
    if (config.username.trim().isEmpty) return "Error: El usuario es obligatorio.";

    String key = _generateKey(config);

    // 2. Si ya está conectado, no re-conectamos (ahorro de recursos)
    if (activeConnections.containsKey(key) && activeConnections[key]!.isConnected) {
      return null;
    }

    // 3. Intento de conexión usando tu clase SSHService
    SSHService newService = SSHService();

    try {
      bool success = await newService.connect(config);

      if (success) {
        activeConnections[key] = newService;
        notifyListeners();
        return null; // Éxito total
      } else {
        return "Fallo de autenticación: Revisa tus credenciales o llave SSH.";
      }
    } catch (e) {
      return "Error de red: No se pudo establecer el socket con ${config.host}.";
    }
  }

  /// Cierra una conexión específica y libera memoria
  void disconnect(GeneralConfig config) {
    String key = _generateKey(config);
    if (activeConnections.containsKey(key)) {
      activeConnections[key]!.disconnect();
      activeConnections.remove(key);
      notifyListeners();
    }
  }

  /// Limpieza total (Criterio de seguridad al cerrar perfil)
  void disconnectAll() {
    for (var service in activeConnections.values) {
      service.disconnect();
    }
    activeConnections.clear();
    notifyListeners();
  }

  String _generateKey(GeneralConfig config) {
    return "${config.username}@${config.host}:${config.port}";
  }
}