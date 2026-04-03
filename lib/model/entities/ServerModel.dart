

import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/services/SSHService.dart';


class ServerModel {
  final ServerConfig config;
  final SSHService sshService = SSHService();

  ServerModel({required this.config});

  Future<bool> connect() async {
    bool ok = await sshService.connect(config);
    return ok;
  }

}