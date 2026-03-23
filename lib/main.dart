import 'package:flutter/material.dart';
import 'package:pro_tocol/entity//SSHService.dart';
import 'package:pro_tocol/entity/DataBaseEntities.dart';
import 'package:pro_tocol/entity/GeneralConfig.dart';
import 'package:pro_tocol/entity/FileNode.dart';
import 'package:pro_tocol/entity/TempSesion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const SSHTestScreen(),
    );
  }
}

class SSHTestScreen extends StatefulWidget {
  const SSHTestScreen({super.key});

  @override
  State<SSHTestScreen> createState() => _SSHTestScreenState();
}

class _SSHTestScreenState extends State<SSHTestScreen> {
  // Instancia de tu servicio
  final SSHService _sshService = SSHService();

  // Controladores de texto para el formulario
  final _hostController = TextEditingController(text: '192.168.1.10');
  final _userController = TextEditingController(text: 'root');
  final _passController = TextEditingController();

  bool _isLoading = false;
  List<FileNode> _files = [];
  String _terminalOutput = "Consola lista...";

  // Función para conectar
  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);

    final config = TempSession(
      host: _hostController.text,
      username: _userController.text,
      port: 22,
      password: _passController.text,
    );

    final success = await _sshService.connect(config);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Conectado exitosamente!')),
      );
      _loadFiles();
    } else {
      showDialog(
        context: context,
        builder: (c) => const AlertDialog(title: Text("Error de conexión")),
      );
    }
    setState(() => _isLoading = false);
  }

  // Probar SFTP internamente
  Future<void> _loadFiles() async {
    if (_sshService.sftp != null) {
      final list = await _sshService.sftp!.listDirectory('/');
      setState(() => _files = list);
    }
  }

  // Probar un comando rápido (Botón)
  Future<void> _runUptime() async {
    final res = await _sshService.runSingleCommand('uptime -p');
    setState(() => _terminalOutput = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SSH Service Tester')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- FORMULARIO ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(controller: _hostController, decoration: const InputDecoration(labelText: 'Host IP')),
                    TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Usuario')),
                    TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleConnect,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Conectar'),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // --- ACCIONES Y SALIDA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _sshService.isConnected ? _runUptime : null, child: const Text('Get Uptime')),
                ElevatedButton(onPressed: _sshService.isConnected ? _loadFiles : null, child: const Text('Refresh Files')),
              ],
            ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              color: Colors.black,
              child: Text(_terminalOutput, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
            ),

            // --- LISTA DE ARCHIVOS (SFTP) ---
            Expanded(
              child: ListView.builder(
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return ListTile(
                    leading: Icon(file.isDirectory ? Icons.folder : Icons.insert_drive_file),
                    title: Text(file.name),
                    subtitle: Text('${file.type.name} - ${file.sizeInBytes} bytes'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}