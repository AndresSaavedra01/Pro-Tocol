
import 'package:isar/isar.dart';

import 'SHHConnection.dart';

part 'Server.g.dart';

@collection
class Server extends SHHConnection {
  Id id = Isar.autoIncrement;
  String alias;

  Server({
    required this.alias,
    required String host,
    required String user,
    required int port,
    required String pass,
  }) : super(host, user, port, pass);
}

