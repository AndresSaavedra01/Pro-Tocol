import 'package:flutter/material.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import '../../controller/ServerController.dart';
import '../pages/ServerPage.dart';

enum WorkspaceState { welcome, loading, connected, error }

class WorkspaceLayout extends StatefulWidget {
  final Profile profile;
  final ServerController serverController;

  const WorkspaceLayout({Key? key, required this.profile, required this.serverController}) : super(key: key);

  @override
  State<WorkspaceLayout> createState() => _WorkspaceLayoutState();
}

class _WorkspaceLayoutState extends State<WorkspaceLayout> {
  WorkspaceState _currentState = WorkspaceState.welcome;
  ServerConfig? _activeServer;
  String _errorMessage = '';
  bool _isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    _refreshServers();
  }

  /// Recarga la lista de servidores desde la base de datos
  Future<void> _refreshServers() async {
    await widget.profile.servers.load();
    if (mounted) setState(() {});
  }

  Future<void> _connectToServer(ServerConfig server) async {
    setState(() {
      _activeServer = server;
      _currentState = WorkspaceState.loading;
    });

    try {
      await widget.serverController.connectToServer(server);
      setState(() => _currentState = WorkspaceState.connected);
    } catch (e) {
      setState(() {
        _currentState = WorkspaceState.error;
        _errorMessage = e.toString();
      });
    }
  }

  /// ---------------------------------------------------------
  /// LÓGICA CRUD DE SERVIDORES
  /// ---------------------------------------------------------

  Future<void> _showServerDialog({ServerConfig? serverToEdit}) async {
    final isEditing = serverToEdit != null;
    final formKey = GlobalKey<FormState>();

    // Controladores
    final hostCtrl = TextEditingController(text: isEditing ? serverToEdit.host : '');
    final userCtrl = TextEditingController(text: isEditing ? serverToEdit.username : '');
    final portCtrl = TextEditingController(text: isEditing ? serverToEdit.port.toString() : '22');
    final passCtrl = TextEditingController(text: isEditing ? serverToEdit.password : '');
    final keyCtrl = TextEditingController(text: isEditing ? serverToEdit.privateKey : '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Servidor' : 'Nuevo Servidor'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: hostCtrl,
                    decoration: const InputDecoration(labelText: 'Host / IP'),
                    validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: userCtrl,
                          decoration: const InputDecoration(labelText: 'Usuario'),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: portCtrl,
                          decoration: const InputDecoration(labelText: 'Puerto'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text('Autenticación (Usa uno u otro)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  TextFormField(
                    controller: keyCtrl,
                    decoration: const InputDecoration(labelText: 'Llave Privada (RSA/ED25519)'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pass = passCtrl.text.trim().isEmpty ? null : passCtrl.text;
                  final key = keyCtrl.text.trim().isEmpty ? null : keyCtrl.text;

                  if (pass == null && key == null) {
                    _showSnackBar('Debes ingresar contraseña o llave privada', isError: true);
                    return;
                  }

                  Navigator.pop(context);
                  await _saveServer(
                    host: hostCtrl.text,
                    user: userCtrl.text,
                    port: int.parse(portCtrl.text),
                    pass: pass,
                    key: key,
                    serverToEdit: serverToEdit,
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveServer({
    required String host,
    required String user,
    required int port,
    String? pass,
    String? key,
    ServerConfig? serverToEdit,
  }) async {
    try {
      if (serverToEdit == null) {
        await widget.serverController.createAndLinkServer(
          profileId: widget.profile.id,
          host: host,
          username: user,
          port: port,
          password: pass,
          privateKey: key,
        );
        _showSnackBar('Servidor creado');
      } else {
        serverToEdit.host = host;
        serverToEdit.username = user;
        serverToEdit.port = port;
        serverToEdit.password = pass;
        serverToEdit.privateKey = key;
        await widget.serverController.updateServer(serverToEdit);
        _showSnackBar('Servidor actualizado');
      }
      await _refreshServers();
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _confirmDeleteServer(ServerConfig server) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Servidor'),
        content: Text('¿Eliminar la configuración de ${server.host}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.serverController.deleteServer(server.id);
        if (_activeServer?.id == server.id) {
          setState(() {
            _activeServer = null;
            _currentState = WorkspaceState.welcome;
          });
        }
        await _refreshServers();
        _showSnackBar('Servidor eliminado');
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  /// ---------------------------------------------------------
  /// BUILDERS DE LA VISTA
  /// ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.profileName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSidebarOpen ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
          )
        ],
      ),
      body: Row(
        children: [
          if (_isSidebarOpen)
            Container(
              width: 300, // Un poco más ancho para acomodar los iconos
              color: Theme.of(context).drawerTheme.backgroundColor,
              child: _buildSidebar(),
            ),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final servers = widget.profile.servers.toList();
    return Column(
      children: [
        ListTile(
          title: const Text('SERVIDORES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Añadir servidor',
            onPressed: () => _showServerDialog(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              final isSelected = _activeServer?.id == server.id;

              return ListTile(
                selected: isSelected,
                selectedTileColor: Colors.blue.withOpacity(0.2),
                leading: const Icon(Icons.dns),
                title: Text(server.host),
                subtitle: Text(server.username),
                onTap: () => _connectToServer(server),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showServerDialog(serverToEdit: server),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteServer(server),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_currentState) {
      case WorkspaceState.welcome:
        return const Center(child: Text('Selecciona o crea un servidor en el panel lateral.', style: TextStyle(color: Colors.grey)));
      case WorkspaceState.loading:
        return const Center(child: CircularProgressIndicator());
      case WorkspaceState.error:
        return _buildErrorLayout();
      case WorkspaceState.connected:
        return ServerPage(
          serverConfig: _activeServer!,
          serverController: widget.serverController,
        );
    }
  }

  Widget _buildErrorLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            onPressed: () => _connectToServer(_activeServer!),
          )
        ],
      ),
    );
  }
}