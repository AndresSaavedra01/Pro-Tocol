

import 'package:pro_tocol/entity/DataBaseEntities.dart';
import 'package:pro_tocol/entity/SSHService.dart';


class ServerModel {
  final ServerConfig config;
  final SSHService ssh = SSHService();

  ServerModel({required this.config});

  Future<bool> connect() async {
    bool ok = await ssh.connect(config);
    return ok;
  }

}