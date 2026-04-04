

import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/services/SSHService.dart';


class Server {
  final ServerConfig config;
  final SSHService sshService = SSHService();

  Server({required this.config});

}