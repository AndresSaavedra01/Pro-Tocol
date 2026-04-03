import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';

import '../../controller/ServerController.dart';

class ServerPage extends StatefulWidget {
  final ServerConfig serverConfig;
  final ServerController serverController;

  const ServerPage({Key? key, required this.serverConfig, required this.serverController}) : super(key: key);

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  late Terminal _terminal;

  // Variables para gestionar el ciclo de vida de la conexión SSH
  SSHSession? _session;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal();
    _initTerminal();
  }

  Future<void> _initTerminal() async {
    try {
      _terminal.write('Conectando a ${widget.serverConfig.host}...\r\n');

      // 1. Obtenemos el servidor activo desde el controlador
      final activeServer = widget.serverController.getActiveServer(widget.serverConfig.id);

      // 2. Creamos la sesión interactiva (shell)
      _session = await activeServer.sshService.createTerminal();

      _terminal.write('\r\n--- Conexión establecida ---\r\n');

      // 3. Vía 1: De SSH a la Pantalla (Lectura)
      _stdoutSub = _session!.stdout.listen((data) {
        if (mounted) {
          _terminal.write(utf8.decode(data));
        }
      });

      _stderrSub = _session!.stderr.listen((data) {
        if (mounted) {
          _terminal.write(utf8.decode(data));
        }
      });

      // 4. Vía 2: Del Teclado al SSH (Escritura)
      _terminal.onOutput = (String data) {
        if (_session != null) {
          _session!.write(Uint8List.fromList(utf8.encode(data)));
        }
      };

      // 5. Manejar el cierre de la sesión por parte del servidor
      _session!.done.then((_) {
        if (mounted) {
          _terminal.write('\r\n\r\n--- Sesión finalizada por el servidor ---\r\n');
        }
      });

    } catch (e) {
      if (mounted) {
        _terminal.write('\r\nError iniciando terminal: $e\r\n');
      }
    }
  }

  @override
  void dispose() {
    // Es vital cancelar las escuchas y cerrar la sesión del shell 
    // al destruir este widget para evitar fugas de memoria.
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _session?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Terminal', icon: Icon(Icons.terminal)),
              Tab(text: 'SFTP', icon: Icon(Icons.folder)),
              Tab(text: 'Métricas', icon: Icon(Icons.analytics)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // PESTAÑA 1: TERMINAL XTERM
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(8.0),
                  child: TerminalView(_terminal),
                ),

                // PESTAÑA 2: Futuro SFTP
                const Center(child: Text('Explorador de archivos (Próximamente)')),

                // PESTAÑA 3: Futuras Métricas
                const Center(child: Text('Métricas del sistema (Próximamente)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}