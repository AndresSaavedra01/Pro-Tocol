import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cliente SSH',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const LoginScreen(),
    );
  }
}

// --- PANTALLA DE FORMULARIO ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ipController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  void _conectar() {
    if (_ipController.text.isEmpty ||
        _userController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos')),
      );
      return;
    }

    // Navegar a la pantalla de la terminal pasando los datos
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TerminalScreen(
          ip: _ipController.text,
          username: _userController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conexión SSH')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Dirección IP',
                prefixIcon: Icon(Icons.computer),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _conectar,
                child: const Text('Conectar', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE LA TERMINAL ---
class TerminalScreen extends StatefulWidget {
  final String ip;
  final String username;
  final String password;

  const TerminalScreen({
    super.key,
    required this.ip,
    required this.username,
    required this.password,
  });

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final Terminal terminal;
  SSHClient? client;
  SSHSession? session;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    terminal = Terminal();
    _iniciarSSH();
  }

  Future<void> _iniciarSSH() async {
    try {
      // 1. Establecer la conexión por socket
      final socket = await SSHSocket.connect(widget.ip, 22);

      // 2. Autenticar el cliente SSH
      client = SSHClient(
        socket,
        username: widget.username,
        onPasswordRequest: () => widget.password,
      );

      // 3. Solicitar una shell (terminal interactiva)
      session = await client!.shell(
        pty: SSHPtyConfig(
            width: terminal.viewWidth,
            height: terminal.viewHeight
        ),
      );

      setState(() {
        _isConnecting = false;
      });

      // 4. Conectar la salida (stdout/stderr) del servidor a nuestra terminal visual
      session!.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.write);

      session!.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.write);

      // 5. Conectar nuestras teclas (inputs) al servidor SSH
      terminal.onOutput = (data) {
        session!.write(utf8.encode(data));
      };

      // Si la sesión termina desde el lado del servidor, cerramos la pantalla
      await session!.done;
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });
      terminal.write('\r\n\x1B[31mError de conexión: $e\x1B[0m\r\n');
    }
  }

  @override
  void dispose() {
    client?.close(); // Siempre cerramos el cliente al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}@${widget.ip}'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isConnecting
            ? const Center(child: CircularProgressIndicator())
            : TerminalView(terminal),
      ),
    );
  }
}