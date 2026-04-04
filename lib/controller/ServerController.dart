import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/entities/ServerModel.dart';
import 'package:pro_tocol/model/repositories/ServerRepository.dart';
import 'package:pro_tocol/model/repositories/ProfileRepository.dart';
import 'package:pro_tocol/model/entities/ServerMetrics.dart';

class ServerController {
  final ServerRepository _serverRepository;
  final ProfileRepository _profileRepository;

  // MAPA VITAL: Mantiene vivas las conexiones. La llave es el ID del ServerConfig.
  final Map<int, ServerModel> _activeConnections = {};

  ServerController(this._serverRepository, this._profileRepository);

  /// 1. VALIDACIÓN Y CREACIÓN
  Future<ServerConfig> createAndLinkServer({
    required int profileId,
    required String host,
    required String username,
    required int port,
    String? password,
    String? privateKey,
  }) async {
    _validateServerInputs(host, username, port, password, privateKey);

    // Verificamos que el perfil exista antes de crear el servidor
    final profile = await _profileRepository.getProfileById(profileId);
    if (profile == null) {
      throw Exception('El perfil con ID $profileId no existe.');
    }

    final newConfig = ServerConfig()
      ..host = host.trim()
      ..username = username.trim()
      ..port = port
      ..password = password
      ..privateKey = privateKey;

    // Guarda el servidor y lo vincula al perfil usando tu DAO
    await _profileRepository.addServerToProfile(profileId, newConfig);

    return newConfig;
  }

  /// 2. GESTIÓN DE CONEXIONES (SERVICIOS)
  Future<void> connectToServer(ServerConfig config) async {
    final serverId = config.id;

    // Si ya está conectado o en memoria, no hacemos nada
    if (_activeConnections.containsKey(serverId) &&
        _activeConnections[serverId]!.sshService.isConnected) {
      return;
    }

    // Le pedimos al repositorio que ensamble el dominio (Config + SSHService)
    final server = _serverRepository.buildServerFromConfig(config);

    try {
      // Usamos el servicio interno para conectar.
      // Al implementar GeneralConfig, config pasa directo sin problemas.
      await server.sshService.connect(config);

      // Si fue exitoso, lo guardamos en las conexiones activas
      _activeConnections[serverId] = server;
    } catch (e) {
      throw Exception('Fallo al conectar con ${config.host}: $e');
    }
  }

  Future<void> disconnectFromServer(int serverId) async {
    if (_activeConnections.containsKey(serverId)) {
      _activeConnections[serverId]!.sshService.disconnect();
      _activeConnections.remove(serverId);
    }
  }

  /// 3. EJECUCIÓN DE SERVICIOS
  Future<ServerMetrics> getServerMetrics(int serverId) async {
    final server = getActiveServer(serverId);
    return await server.sshService.fetchMetrics();
  }

  Future<String> executeCommand(int serverId, String command) async {
    final server = getActiveServer(serverId);
    return await server.sshService.runSingleCommand(command);
  }

  /// Utilidad interna para asegurar que operamos sobre un servidor activo
  ServerModel getActiveServer(int serverId) {
    final server = _activeConnections[serverId];
    if (server == null || !server.sshService.isConnected) {
      throw Exception('El servidor no está conectado. Conecta primero antes de ejecutar comandos.');
    }
    return server;
  }

  /// Lógica de validación pura
  void _validateServerInputs(String host, String username, int port, String? password, String? privateKey) {
    if (host.trim().isEmpty) throw ArgumentError('El host es obligatorio.');
    if (username.trim().isEmpty) throw ArgumentError('El usuario es obligatorio.');
    if (port <= 0 || port > 65535) throw ArgumentError('El puerto debe ser entre 1 y 65535.');

    final hasPassword = password != null && password.isNotEmpty;
    final hasKey = privateKey != null && privateKey.isNotEmpty;

    if (!hasPassword && !hasKey) {
      throw ArgumentError('Debes proporcionar una contraseña o una llave privada RSA/ED25519.');
    }
  }

  /// Actualiza una configuración de servidor existente
  Future<void> updateServer(ServerConfig config) async {
    _validateServerInputs(config.host, config.username, config.port, config.password, config.privateKey);
    // Isar maneja la actualización automáticamente si el ID ya existe usando put()
    await _serverRepository.saveServerConfig(config);
  }

  /// Elimina un servidor de la base de datos y cierra su conexión si estaba activa
  Future<void> deleteServer(int id) async {
    await disconnectFromServer(id); // Primero nos aseguramos de no dejar conexiones huérfanas
    await _serverRepository.deleteServer(id);
  }
}