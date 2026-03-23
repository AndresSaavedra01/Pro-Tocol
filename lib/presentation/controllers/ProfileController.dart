import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:pro_tocol/entity/DataBaseEntities.dart';
import 'package:pro_tocol/entity/ServerModel.dart';

class ProfileController extends ChangeNotifier {
  final Isar isar;

  List<Profile> allProfiles = [];
  Profile? activeProfile;
  List<ServerModel> activeServers = [];

  ProfileController({required this.isar}) {
    // Al iniciar el controlador, cargamos todos los perfiles de la BD
    loadAllProfiles();
  }

  // ==========================================
  // CRUD PERFILES (Profile)
  // ==========================================

  /// [READ] Cargar todos los perfiles guardados
  Future<void> loadAllProfiles() async {
    allProfiles = await isar.profiles.where().findAll();
    notifyListeners();
  }

  /// [CREATE] Crear un nuevo perfil
  Future<void> createProfile(String name) async {
    final newProfile = Profile()..profileName = name;
    
    await isar.writeTxn(() async {
      await isar.profiles.put(newProfile);
    });
    
    await loadAllProfiles();
  }

  /// Seleccionar perfil activo y cargar sus servidores
  void setActiveProfile(Profile profile) {
    activeProfile = profile;
    // Envolvemos la configuración en nuestro ServerModel lógico
    activeServers = profile.servers.map((config) => ServerModel(config: config)).toList();
    notifyListeners();
  }

  // ==========================================
  // CRUD SERVIDORES (ServerConfig / ServerModel)
  // ==========================================

  /// [CREATE] Agregar un nuevo servidor al perfil activo
  Future<void> addServer(ServerConfig newServerConfig) async {
    if (activeProfile == null) return;

    await isar.writeTxn(() async {
      // 1. Guardamos el servidor en la BD
      await isar.serverConfigs.put(newServerConfig);
      // 2. Lo vinculamos al perfil actual
      activeProfile!.servers.add(newServerConfig);
      await activeProfile!.servers.save();
    });

    // Actualizamos la vista
    activeServers.add(ServerModel(config: newServerConfig));
    notifyListeners();
  }

  /// [UPDATE] Actualizar los datos de un servidor existente
  Future<void> updateServer(ServerConfig updatedConfig) async {
    await isar.writeTxn(() async {
      await isar.serverConfigs.put(updatedConfig); // .put actualiza si el ID ya existe
    });
    
    // Refrescamos la lista local recargando el perfil
    if (activeProfile != null) {
      setActiveProfile(activeProfile!);
    }
  }

  /// [DELETE] Borrar un servidor de la BD y la lista
  Future<void> deleteServer(ServerModel server) async {
    if (server.ssh.isConnected) {
      server.ssh.disconnect();
    }

    await isar.writeTxn(() async {
      await isar.serverConfigs.delete(server.config.id);
    });

    activeServers.remove(server);
    notifyListeners();
  }
}