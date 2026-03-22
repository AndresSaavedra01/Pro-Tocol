

import 'package:pro_tocol/entity/SHHConnection.dart';

class TempSession extends SHHConnection {
  final DateTime startedAt;
  final String connectionId; // Un ID único para identificar la pestaña abierta

  TempSession({
    required String ip,
    required String user,
    required int port,
    required String pass,
    required this.connectionId,
  }) : startedAt = DateTime.now(),
        super(ip, user, port, pass);
}