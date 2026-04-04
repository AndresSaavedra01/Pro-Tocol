import 'package:flutter/material.dart';

import 'package:pro_tocol/controller/ProfileController.dart';
import 'package:pro_tocol/controller/ServerController.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';

import 'package:pro_tocol/view/components/connection_dialog.dart';
import 'package:pro_tocol/view/components/SshErrorDisplay.dart';
import 'package:pro_tocol/view/components/custom_sidebar.dart';

import '../../controller/TempSessionController.dart';
import '../../model/entities/TempSessionConfig.dart';
import '../theme/AppColors.dart';
import 'ServerPage.dart';
import 'TempSessionPage.dart';

enum ViewType { home, serverView, tempSessionView, loading }

class WorkspacePage extends StatefulWidget {
  final Profile profile;
  final ProfileController profileController;
  final ServerController serverController;
  final TempSessionController tempSessionController; // <--- NUEVO

  const WorkspacePage({
    super.key,
    required this.profile,
    required this.profileController,
    required this.serverController,
    required this.tempSessionController, // <--- REQUERIDO
  });

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  ViewType _currentView = ViewType.home;
  ServerConfig? _selectedServer;
  TempSessionConfig? _selectedTempSession; // <--- CAMBIO DE TIPO
  final List<TempSessionConfig> _tempConfigs = [];

  @override
  void initState() {
    super.initState();
    _refreshServers();
  }

  Future<void> _refreshServers() async {
    await widget.profile.servers.load();
    if (mounted) setState(() {});
  }

  void _goHome() {
    setState(() {
      _currentView = ViewType.home;
      _selectedServer = null;
      _selectedTempSession = null;
    });
  }

  Future<void> _selectServer(ServerConfig server) async {
    setState(() {
      _currentView = ViewType.loading;
      _selectedServer = server;
      _selectedTempSession = null;
    });

    try {
      await widget.serverController.connectToServer(server);
      if (mounted) setState(() => _currentView = ViewType.serverView);
    } catch (e) {
      if (mounted) {
        _goHome();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => SshErrorDisplay(
            errorMessage: e.toString(),
            onRetry: () => Navigator.pop(context),
          ),
        ));
      }
    }
  }

  Future<void> _selectTempSession(TempSessionConfig config) async {
    setState(() {
      _currentView = ViewType.loading;
      _selectedTempSession = config;
      _selectedServer = null;
    });

    try {
      // Intentamos conectar usando el controlador de sesiones temporales
      await widget.tempSessionController.createAndConnect(
        host: config.host,
        username: config.username,
        port: config.port,
        password: config.password,
        privateKey: config.privateKey,
      );

      if (mounted) setState(() => _currentView = ViewType.tempSessionView);
    } catch (e) {
      if (mounted) {
        _goHome();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => SshErrorDisplay(
            errorMessage: e.toString(),
            onRetry: () => Navigator.pop(context),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: CustomSidebar(
        servers: widget.profile.servers.toList(),
        tempSessions: _tempConfigs.map((c) => ServerConfig()
          ..host = c.host
          ..username = c.username
          ..id = c.host.hashCode
        ).toList(),

        activeServer: _selectedServer,
        // Para que el resaltado funcione con sesiones temporales:
        activeTempSession: _selectedTempSession != null
            ? (ServerConfig()..host = _selectedTempSession!.host..id = _selectedTempSession!.host.hashCode)
            : null,

        onAddServer: () => _showServerDialog(context),
        onSelectServer: _selectServer,
        onEditServer: (s) => _showEditServerDialog(context, s),
        onDeleteServer: (s) {
          _confirmDelete(context, s.host, () async {
            await widget.serverController.deleteServer(s.id);
            if (_selectedServer?.id == s.id) _goHome();
            _refreshServers();
          });
        },

        onAddTempSession: () => _showTempSessionDialog(context),
        onSelectTempSession: (s) {
          final config = _tempConfigs.firstWhere((c) => c.host == s.host);
          _selectTempSession(config);
        },

        // CORRECCIÓN: Implementación del método de editar
        onEditTempSession: (s) {
          final config = _tempConfigs.firstWhere((c) => c.host == s.host);
          _showEditTempSessionDialog(context, config);
        },

        onDeleteTempSession: (s) {
          _confirmDelete(context, s.host, () async {
            await widget.tempSessionController.disconnectAndRemove(s.host);
            setState(() {
              _tempConfigs.removeWhere((c) => c.host == s.host);
              if (_selectedTempSession?.host == s.host) _goHome();
            });
          });
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _getAppBarTitle(),
            key: ValueKey<String>(_getAppBarTitle()),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: AppTheme.mainBackground,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildMainContent(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        onTap: (index) {
          if (index == 0) _goHome();
          if (index == 1) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentView) {
      case ViewType.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case ViewType.serverView:
        return ServerPage(
          key: ValueKey('server_${_selectedServer!.id}'),
          serverConfig: _selectedServer!,
          serverController: widget.serverController,
        );
      case ViewType.tempSessionView:
      // --- AQUÍ USAMOS LA NUEVA PÁGINA ---
        return TempSessionPage(
          key: ValueKey('temp_${_selectedTempSession!.host}'),
          tempConfig: _selectedTempSession!,
          tempController: widget.tempSessionController,
        );
      case ViewType.home:
      default:
        return _buildWelcomeView();
    }
  }

  String _getAppBarTitle() {
    if (_currentView == ViewType.serverView) return "Servidor";
    if (_currentView == ViewType.tempSessionView) return "Terminal";
    if (_currentView == ViewType.loading) return "Conectando...";
    return "Inicio";
  }

  Widget _buildWelcomeView() {
    return Padding(
      key: const ValueKey('welcome_view'),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: AppTheme.glassCard,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: AppColors.textPrimary, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('¡Bienvenido!', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Perfil: ${widget.profile.profileName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 20),
                const Text(
                  'Usa el menú lateral para gestionar\nservidores y sesiones',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String itemName, VoidCallback onConfirm) {
    // Si tienes el dialog oscuro modularizado, úsalo aquí.
    // De momento mantengo la misma lógica de UI que tenías en WorkspacePage.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: const Text('¿Eliminar conexión?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar "$itemName"? Esta acción no se puede deshacer.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConnectionFormDialog(
        title: 'Crear Servidor',
        subtitle: 'Se guardará en Isar y se conectará ahora',
        buttonText: 'Guardar y Conectar',
        onSubmit: (host, user, pass, port) async {
          try {
            final newServer = await widget.serverController.createAndLinkServer(
              profileId: widget.profile.id,
              host: host,
              username: user,
              port: port,
              password: pass,
            );

            if (context.mounted) {
              Navigator.of(dialogContext).pop();
              await _refreshServers();
              _selectServer(newServer);
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SshErrorDisplay(errorMessage: e.toString(), onRetry: () => Navigator.pop(context))));
            }
          }
        },
      ),
    );
  }

  void _showEditServerDialog(BuildContext context, ServerConfig server) {
    showDialog(
      context: context,
      builder: (context) => ConnectionFormDialog(
        title: 'Editar Servidor',
        subtitle: 'Actualiza los datos de conexión',
        buttonText: 'Guardar Cambios',
        initialHost: server.host,
        initialUser: server.username,
        initialPass: server.password,
        onSubmit: (host, user, pass, port) async {
          server.host = host;
          server.username = user;
          server.password = pass;
          server.port = port;
          await widget.serverController.updateServer(server);
          if (context.mounted) {
            Navigator.pop(context);
            _refreshServers();
          }
        },
      ),
    );
  }

  void _showTempSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConnectionFormDialog(
        title: 'Nueva Sesión Temporal',
        subtitle: 'Los datos no se guardarán al cerrar la app', // Agregado
        buttonText: 'Conectar Ahora', // Agregado
        onSubmit: (host, user, pass, port) async {
          final config = TempSessionConfig(
            host: host,
            username: user,
            password: pass,
            port: port,
          );
          setState(() => _tempConfigs.add(config));
          Navigator.pop(dialogContext);
          _selectTempSession(config);
        },
      ),
    );
  }

// CORRECCIÓN: Ahora recibe TempSessionConfig en lugar de ServerConfig
  void _showEditTempSessionDialog(BuildContext context, TempSessionConfig config) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConnectionFormDialog(
        title: 'Editar Sesión Temporal',
        subtitle: 'Actualiza los datos para esta sesión',
        buttonText: 'Actualizar',
        initialHost: config.host,
        initialUser: config.username,
        initialPass: config.password,
        onSubmit: (host, user, pass, port) async {
          // Usamos el controlador temporal para desconectar por host
          await widget.tempSessionController.disconnectAndRemove(config.host);

          setState(() {
            config.host = host;
            config.username = user;
            config.password = pass;
            config.port = port;
          });

          if (context.mounted) {
            Navigator.pop(dialogContext);
            _selectTempSession(config); // Reconecta con los nuevos datos
          }
        },
      ),
    );
  }
}