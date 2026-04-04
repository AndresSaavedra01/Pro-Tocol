
import 'package:pro_tocol/model/entities/TempSession.dart';
import 'package:pro_tocol/model/entities/TempSessionConfig.dart';
import 'package:pro_tocol/model/repositories/TempSessionRepository.dart';

class TempSessionController {
  final TempSessionRepository _repository;

  // Mapa para gestionar las sesiones activas en ejecución (Key: un ID único generado en RAM)
  final Map<String, TempSession> _activeSessions = {};

  TempSessionController(this._repository);

  Future<TempSession> createAndConnect({
    required String host,
    required String username,
    required int port,
    String? password,
    String? privateKey,
  }) async {
    // Validamos los campos igual que en el servidor persistente
    _validateInputs(host, username, port, password, privateKey);

    // Creamos la configuración volátil
    final config = TempSessionConfig(password: password,
        host: host,
        username: username,
        port: port,
        privateKey: privateKey
    );


    // El repositorio ensambla el modelo (Config + SSHService)
    final session = _repository.buildTempSession(config);

    try {
      // Intentamos la conexión SSH
      await session.sshService.connect(config);

      // Si tiene éxito, la guardamos en nuestro mapa de sesiones activas
      // Usamos el host como llave temporal o un hash de la config
      _activeSessions[host] = session;

      return session;
    } catch (e) {
      throw Exception('Fallo al conectar sesión temporal con $host: $e');
    }
  }

  /// 2. GESTIÓN DE ESTADO
  Future<void> disconnectAndRemove(String host) async {
    if (_activeSessions.containsKey(host)) {
      final session = _activeSessions[host]!;
      await _repository.removeTempSession(session);
      _activeSessions.remove(host);
    }
  }


  Future<String> runCommand(String host, String command) async {
    final session = _getValidSession(host);
    return await session.sshService.runSingleCommand(command);
  }

  /// Utilidad interna para asegurar que la sesión existe y está conectada
  TempSession _getValidSession(String host) {
    final session = _activeSessions[host];
    if (session == null || !session.sshService.isConnected) {
      throw Exception('La sesión temporal en $host no está activa.');
    }
    return session;
  }

  /// Lógica de validación pura (DRY: Reutiliza la misma lógica de ServerController)
  void _validateInputs(String host, String username, int port, String? password, String? privateKey) {
    if (host.trim().isEmpty) throw ArgumentError('El host es obligatorio.');
    if (username.trim().isEmpty) throw ArgumentError('El usuario es obligatorio.');
    if (port <= 0 || port > 65535) throw ArgumentError('Puerto inválido.');

    if ((password == null || password.isEmpty) && (privateKey == null || privateKey.isEmpty)) {
      throw ArgumentError('Se requiere contraseña o llave privada.');
    }
  }

  /// Retorna la lista de sesiones para mostrar en el Sidebar
  List<TempSession> getActiveSessions() {
    return _activeSessions.values.toList();
  }


  TempSession getValidSession(String host) {
    final session = _activeSessions[host];
    if (session == null || !session.sshService.isConnected) {
      throw Exception('La sesión temporal en $host no está activa.');
    }
    return session;
  }
}