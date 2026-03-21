

import 'package:pro_tocol/entity/BaseConnection.dart';

class TempSession extends Baseconnection {
  final DateTime startedAt;
  final String connectionId; // Un ID único para identificar la pestaña abierta

  TempSession({
    required String ip,
    required String user,
    required String pass,
    required this.connectionId,
  }) : startedAt = DateTime.now(),
        super(ip, user, pass);
}