import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:pro_tocol/entity/DataBaseEntities.dart';
import 'package:pro_tocol/entity/TempSession.dart';
import 'package:pro_tocol/entity/ServerModel.dart';
import 'package:pro_tocol/entity/SSHService.dart';

class ProfileController extends ChangeNotifier {
  final Isar isar; // Instancia de la base de datos Isar

  // Perfil activo actualmente
  Profile? activeProfile;

  // Listas para renderizar en el Sidebar
  List<ServerModel> activeServers = [];
  
  // Como TempSession no tiene un SSHService propio (a diferencia de ServerModel),
  // usamos un Map para guardar la sesión y su conexión activa.
  Map<TempSession, SSHService> activeTempSessions = {};

  ProfileController({required this.isar});

  /// Criterio: Manejar el perfil activo en memoria
  void setActiveProfile(Profile profile) {
    activeProfile = profile;
    // Cargamos los servidores de Isar y los envolvemos en el ServerModel
    activeServers = profile.servers.map((config) => ServerModel(config: config)).toList();
    notifyListeners();
  }

  /// Criterio: Al darle "Eliminar" a un Server (Borrar BD y Sidebar)
  Future<void> deleteServer(ServerModel server) async {
    // 1. Cerramos la conexión SSH por seguridad si estaba activa
    if (server.ssh.isConnected) {
      server.ssh.disconnect();
    }

    // 2. Lo borramos de la base de datos Isar
    await isar.writeTxn(() async {
      await isar.serverConfigs.delete(server.config.id);
    });

    // 3. Lo quitamos de la memoria y actualizamos la UI (Sidebar)
    activeServers.remove(server);
    notifyListeners();
  }

  /// Criterio: Al darle "Eliminar" a TempSession (Solo cerrar conexión y Sidebar)
  void deleteTempSession(TempSession session) {
    // 1. Cerramos la conexión SSH (No tocamos Isar porque viven en RAM)
    activeTempSessions[session]?.disconnect();

    // 2. Lo quitamos de la memoria y actualizamos la UI (Sidebar)
    activeTempSessions.remove(session);
    notifyListeners();
  }

  // --- Metodos de utilidad para agregar conexiones ---

  void addTempSession(TempSession session, SSHService sshService) {
    activeTempSessions[session] = sshService;
    notifyListeners();
  }
}