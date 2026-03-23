
import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:pro_tocol/entity/GeneralConfig.dart'; // Tu interfaz/clase base

import 'SFTPService.dart';
import 'ServerMetrics.dart';

class SSHService {
  SSHClient? _client;
  SFTPService? _sftpService;

  bool get isConnected => _client != null;

  SFTPService? get sftp => _sftpService;

  Future<bool> connect(GeneralConfig details) async {
    try {
      final socket = await SSHSocket.connect(details.host, details.port);

      List<SSHKeyPair> identities = [];
      String? Function()? passwordHandler;

      // PRIORIDAD 1: Llave Privada (Key)
      if (details.privateKey != null && details.privateKey!.trim().isNotEmpty) {
        identities = SSHKeyPair.fromPem(details.privateKey!);
      }
      // PRIORIDAD 2: Contraseña (Solo si no hay llave)
      else if (details.password != null && details.password!.isNotEmpty) {
        passwordHandler = () => details.password;
      }

      _client = SSHClient(
        socket,
        username: details.username,
        onPasswordRequest: passwordHandler, // Será null si usamos Key
        identities: identities,             // Será lista vacía si usamos Pass
      );

      // Inicializar el servicio SFTP interno
      _sftpService = SFTPService(_client!);

      return true;
    } catch (e) {
      _cleanup();
      return false;
    }
  }

  // 1. Para BOTONES: Ejecuta y retorna el String
  Future<String> runSingleCommand(String command) async {
    if (_client == null) return 'Error: Desconectado';
    final result = await _client!.run(command);
    return utf8.decode(result).trim();
  }

  // 2. Para MÉTRICAS: Timer-ready
  Future<ServerMetrics> fetchMetrics() async {
    if (_client == null) throw Exception('No conectado');

    final rawData = await runSingleCommand(
        "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}'; free -m | awk 'NR==2{print \$3,\$2}'; df -h / --output=pcent | tail -1"
    );

    return ServerMetrics.fromRawOutput(rawData);
  }

  // 3. Para SHELL: Terminal interactiva
  Future<SSHSession> createTerminal() async {
    if (_client == null) throw Exception('Cliente no inicializado');
    return await _client!.shell(
      pty: SSHPtyConfig(width: 100, height: 30),
    );
  }

  void disconnect() {
    _cleanup();
  }

  void _cleanup() {
    _client?.close();
    _client = null;
    _sftpService = null; // Limpiamos la referencia del servicio hijo
  }
}