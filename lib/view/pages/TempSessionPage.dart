
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';

import 'package:pro_tocol/controller/TempSessionController.dart';
import 'package:pro_tocol/model/entities/TempSession.dart';
import 'package:pro_tocol/model/entities/TempSessionConfig.dart';

import '../theme/AppColors.dart';


class TempSessionPage extends StatefulWidget {
  final TempSessionConfig tempConfig;
  final TempSessionController tempController;

  const TempSessionPage({
    super.key,
    required this.tempConfig,
    required this.tempController,
  });

  @override
  State<TempSessionPage> createState() => _TempSessionPageState();
}

class _TempSessionPageState extends State<TempSessionPage> {
  late final Terminal terminal;
  TempSession? _activeSession;
  SSHSession? _shellSession;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: 10000);
    _connectToTerminal();
  }

  @override
  void dispose() {
    _shellSession?.close(); // Es vital cerrar el shell al salir de la vista
    super.dispose();
  }


  Future<void> _connectToTerminal() async {
    try {
      // 1. Obtenemos la sesión viva desde la memoria RAM del controlador
      _activeSession = widget.tempController.getValidSession(widget.tempConfig.host);

      // 2. Iniciamos la sesión con un tamaño base seguro
      _shellSession = await _activeSession!.sshService.createTerminal(
        width: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
        height: terminal.viewHeight > 0 ? terminal.viewHeight : 24,
      );

      // 3. Listener para cambios dinámicos de tamaño (rotación, teclado, etc.)
      terminal.onResize = (width, height, cursorWidth, cursorHeight) {
        if (width > 0 && height > 0) {
          _shellSession?.resizeTerminal(width, height);
        }
      };

      // --- SOLUCIÓN UNIVERSAL PARA EL CURSOR (SM-A315G) ---
      _startUniversalSync(_shellSession!);

      // 4. Escuchamos y escribimos en los flujos de datos
      _shellSession!.stdout.listen((data) {
        if (mounted) terminal.write(utf8.decode(data, allowMalformed: true));
      });

      _shellSession!.stderr.listen((data) {
        if (mounted) terminal.write(utf8.decode(data, allowMalformed: true));
      });

      terminal.onOutput = (input) {
        _shellSession!.stdin.add(utf8.encode(input));
      };

      // Reseteamos y notificamos éxito
      terminal.write('\x1Bc');
      terminal.write('\x1B[32mSesión temporal sincronizada correctamente.\x1B[0m\r\n\n');

    } catch (e) {
      if (mounted) {
        terminal.write('\x1B[31mError al iniciar la terminal: $e\x1B[0m\r\n');
      }
    }
  }

  /// Bucle de sincronización activa para forzar el tamaño correcto en el servidor
  void _startUniversalSync(SSHSession session) {
    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      attempts++;

      if (mounted && terminal.viewWidth > 0) {
        // Sincronizamos el protocolo PTY
        session.resizeTerminal(terminal.viewWidth, terminal.viewHeight);

        // Reforzamos el driver de terminal en el servidor remoto
        try {
          await _activeSession!.sshService.runSingleCommand(
              "stty cols ${terminal.viewWidth} rows ${terminal.viewHeight}"
          );
        } catch (e) {
          debugPrint("Error stty: $e");
        }

        // Detenemos el bucle tras asegurar la sincronización
        if (attempts >= 3) timer.cancel();
      }

      if (attempts > 10) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionString = "${widget.tempConfig.username}@${widget.tempConfig.host}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            const Text('Sesión Temporal', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(connectionString, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        // Al no haber pestañas (Tabs), no necesitamos la propiedad 'bottom'
      ),
      body: _buildTerminalView(),
    );
  }

  Widget _buildTerminalView() {
    return Container(
      color: AppColors.terminalBg,
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TerminalView(
            terminal,
            autofocus: true,
            backgroundOpacity: 1,
            theme: TerminalTheme(
              cursor: AppColors.textPrimary,
              selection: Colors.blueAccent.withOpacity(0.4),
              foreground: AppColors.textPrimary,
              background: AppColors.background,
              black: Colors.black,
              red: AppColors.error,
              green: AppColors.success,
              yellow: Colors.yellowAccent,
              blue: Colors.blueAccent,
              magenta: Colors.purpleAccent,
              cyan: Colors.cyanAccent,
              white: AppColors.textPrimary,
              brightBlack: Colors.grey,
              brightRed: Colors.red,
              brightGreen: Colors.green,
              brightYellow: Colors.yellow,
              brightBlue: Colors.blue,
              brightMagenta: Colors.purple,
              brightCyan: Colors.cyan,
              brightWhite: Colors.white,
              searchHitBackground: Colors.yellowAccent.withOpacity(0.3),
              searchHitBackgroundCurrent: Colors.orangeAccent.withOpacity(0.5),
              searchHitForeground: Colors.black,
            ),
            textStyle: const TerminalStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}