
import 'package:isar/isar.dart';
import 'package:pro_tocol/model/daos/ServerConfigDAO.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/entities/ServerModel.dart';

class ServerRepository {
  final ServerConfigDAO _serverConfigDAO;

  ServerRepository(this._serverConfigDAO);

  /// Guarda solo la entidad de datos (ServerConfig) en Isar.
  Future<void> saveServerConfig(ServerConfig config) async {
    await _serverConfigDAO.saveServerConfig(config);
  }

  /// Elimina la configuración de la base de datos.
  Future<bool> deleteServer(Id id) async {
    return await _serverConfigDAO.deleteServer(id);
  }

  /// Busca servidores por host y los transforma en entidades de dominio 'Server'
  /// listas para iniciar conexiones SSH.
  Future<List<ServerModel>> findServersByHost(String host) async {
    final configs = await _serverConfigDAO.findServersByHost(host);

    // Mapeamos los Data Models (ServerConfig) a Domain Models (Server)
    return configs.map((config) => buildServerFromConfig(config)).toList();
  }

  /// Recupera el perfil padre de un servidor.
  Future<Profile?> getParentProfile(ServerConfig config) async {
    return await _serverConfigDAO.getParentProfile(config);
  }

  /// Método privado de fábrica: Ensambla el modelo de dominio inyectando el servicio.
// En tu ServerRepository.dart
  ServerModel buildServerFromConfig(ServerConfig config) {
    return ServerModel(config: config);
  }

/// (Opcional) Si necesitas obtener un solo Server por ID, deberías agregar
/// un 'getServerById' en tu ServerConfigDAO y luego llamarlo aquí así:
/*
  Future<Server?> getServerById(Id id) async {
    final config = await _serverConfigDAO.getServerById(id);
    if (config != null) {
      return _buildServer(config);
    }
    return null;
  }
  */
}