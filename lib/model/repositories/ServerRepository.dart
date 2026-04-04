
import 'package:isar/isar.dart';
import 'package:pro_tocol/model/daos/ServerConfigDAO.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/entities/Server.dart';

class ServerRepository {
  final ServerConfigDAO _serverConfigDAO;

  ServerRepository(this._serverConfigDAO);

  Future<void> saveServerConfig(ServerConfig config) async {
    await _serverConfigDAO.saveServerConfig(config);
  }

  Future<bool> deleteServer(Id id) async {
    return await _serverConfigDAO.deleteServer(id);
  }


  Server buildServerFromConfig(ServerConfig config) {
    return Server(config: config);
  }

}