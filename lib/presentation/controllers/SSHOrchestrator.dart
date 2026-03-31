import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:pro_tocol/entity/GeneralConfig.dart';
import 'package:pro_tocol/entity/SSHService.dart';

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
        return null; // Éxito total: retorna null indicando que no hay errores
      } else {
        developer.log('El servicio devolvió false al conectar', name: 'SSH_CONNECTION');
        return "Fallo de autenticación: Revisa tus credenciales o llave SSH.";
      }
      
    } on SocketException catch (e) {
      // CAPTURA 1: Timeout o el servidor no responde
      developer.log('Error de Socket/Red: $e', name: 'SSH_CONNECTION');
      return "El servidor tardó mucho en responder o está apagado (Timeout).";
      
    } on SSHAuthFailError catch (e) {
      // CAPTURA 2: Contraseña o llave SSH incorrecta
      developer.log('Error de Autenticación: $e', name: 'SSH_CONNECTION');
      return "Credenciales incorrectas. Verifica tu usuario y contraseña.";
      
    } catch (e) {
      // CAPTURA 3: Cualquier otro error inesperado
      developer.log('Error General: $e', name: 'SSH_CONNECTION');
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