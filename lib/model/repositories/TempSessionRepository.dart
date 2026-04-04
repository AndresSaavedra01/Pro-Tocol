
import 'package:pro_tocol/model/entities/TempSession.dart';
import 'package:pro_tocol/model/entities/TempSessionConfig.dart';

class TempSessionRepository {
  // Al no haber base de datos, mantenemos una lista volátil en memoria
  final List<TempSession> _activeTempSessions = [];


  TempSession buildTempSession(TempSessionConfig config) {
    final session = TempSession(config: config);
    _activeTempSessions.add(session);
    return session;
  }


  List<TempSession> getAllTempSessions() {
    return List.unmodifiable(_activeTempSessions);
  }

  Future<void> removeTempSession(TempSession session) async {
    if (session.sshService.isConnected) {
      session.sshService.disconnect();
    }
    _activeTempSessions.remove(session);
  }

  Future<void> clearAll() async {
    for (var session in _activeTempSessions) {
      if (session.sshService.isConnected) {
        session.sshService.disconnect();
      }
    }
    _activeTempSessions.clear();
  }
}