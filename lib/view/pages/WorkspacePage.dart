import 'package:flutter/material.dart';

import 'package:pro_tocol/controller/ProfileController.dart';
import 'package:pro_tocol/controller/ServerController.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';

import 'package:pro_tocol/view/components/connection_dialog.dart';
import 'package:pro_tocol/view/components/SshErrorDisplay.dart';

import '../theme/AppColors.dart';
import 'ServerPage.dart';

enum ViewType { home, serverView, tempSessionView }

class WorkspacePage extends StatefulWidget {
  final Profile profile;
  final ProfileController profileController;
  final ServerController serverController;

  const WorkspacePage({
    super.key,
    required this.profile,
    required this.profileController,
    required this.serverController,
  });

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  ViewType _currentView = ViewType.home;
  ServerConfig? _selectedServer;
  ServerConfig? _selectedTempSession;

  final List<ServerConfig> _tempSessions = [];

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

  void _selectServer(ServerConfig server) {
    setState(() {
      _selectedServer = server;
      _currentView = ViewType.serverView;
      _selectedTempSession = null;
    });
  }

  void _selectTempSession(ServerConfig session) {
    setState(() {
      _selectedTempSession = session;
      _currentView = ViewType.tempSessionView;
      _selectedServer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildSidebar(context),
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
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
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
      case ViewType.serverView:
        return ServerPage(
          key: ValueKey('server_view_${_selectedServer!.id}'),
          serverConfig: _selectedServer!,
          serverController: widget.serverController,
        );
      case ViewType.tempSessionView:
        return ServerPage(
          key: ValueKey('temp_session_view_${_selectedTempSession!.id}'),
          serverConfig: _selectedTempSession!,
          serverController: widget.serverController,
          isTemporarySession: true,
        );
      case ViewType.home:
      default:
        return _buildWelcomeView();
    }
  }

  String _getAppBarTitle() {
    if (_currentView == ViewType.serverView) return "Servidor";
    if (_currentView == ViewType.tempSessionView) return "Terminal";
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

  Widget _buildSidebar(BuildContext context) {
    final servers = widget.profile.servers.toList();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSidebarHeader(context),
            const Divider(color: AppColors.border, height: 1),

            _buildSectionHeader('Servidores', Icons.dns_outlined, () => _showServerDialog(context)),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: servers.length,
                itemBuilder: (context, index) {
                  final server = servers[index];
                  return _buildSidebarItem(
                    title: server.host,
                    isActive: _selectedServer?.id == server.id,
                    isSession: false,
                    subtitle: server.username,
                    onTap: () {
                      Navigator.pop(context);
                      _selectServer(server);
                    },
                    onEdit: () {
                      Navigator.pop(context);
                      _showEditServerDialog(context, server);
                    },
                    onDelete: () {
                      _confirmDelete(context, server.host, () async {
                        await widget.serverController.deleteServer(server.id);
                        if (_selectedServer?.id == server.id) _goHome();
                        _refreshServers();
                      });
                    },
                  );
                },
              ),
            ),

            const Divider(color: AppColors.border, height: 1),

            _buildSectionHeader('Sesiones Temporales', Icons.access_time, () => _showTempSessionDialog(context)),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _tempSessions.length,
                itemBuilder: (context, index) {
                  final session = _tempSessions[index];
                  return _buildSidebarItem(
                    title: session.host,
                    isActive: _selectedTempSession?.id == session.id,
                    isSession: true,
                    subtitle: session.username,
                    onTap: () {
                      Navigator.pop(context);
                      _selectTempSession(session);
                    },
                    onEdit: () {
                      Navigator.pop(context);
                      _showEditTempSessionDialog(context, session);
                    },
                    onDelete: () {
                      _confirmDelete(context, session.host, () async {
                        await widget.serverController.disconnectFromServer(session.id);
                        setState(() {
                          _tempSessions.remove(session);
                          if (_selectedTempSession?.id == session.id) _goHome();
                        });
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Menú', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textMuted, size: 20),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required String title,
    required bool isActive,
    required bool isSession,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceHighlight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          leading: isSession
              ? null
              : CircleAvatar(radius: 4, backgroundColor: isActive ? AppColors.success : Colors.white24),
          title: Text(title, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textPrimary, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: onDelete),
            ],
          ),
        ),
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
            await widget.serverController.connectToServer(newServer);
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
        subtitle: 'Los datos no se guardarán al cerrar la app',
        buttonText: 'Conectar Ahora',
        onSubmit: (host, user, pass, port) async {
          final tempSession = ServerConfig()
            ..id = DateTime.now().millisecondsSinceEpoch
            ..host = host
            ..username = user
            ..password = pass
            ..port = port;

          try {
            await widget.serverController.connectToServer(tempSession);
            if (context.mounted) {
              setState(() => _tempSessions.add(tempSession));
              Navigator.pop(dialogContext);
              _selectTempSession(tempSession);
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

  void _showEditTempSessionDialog(BuildContext context, ServerConfig session) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConnectionFormDialog(
        title: 'Editar Sesión Temporal',
        subtitle: 'Actualiza los datos para esta sesión',
        buttonText: 'Actualizar',
        initialHost: session.host,
        initialUser: session.username,
        initialPass: session.password,
        onSubmit: (host, user, pass, port) async {
          await widget.serverController.disconnectFromServer(session.id);
          setState(() {
            session.host = host;
            session.username = user;
            session.password = pass;
            session.port = port;
          });
          try {
            await widget.serverController.connectToServer(session);
            if (context.mounted) Navigator.pop(dialogContext);
          } catch (e) {
            debugPrint(e.toString());
          }
        },
      ),
    );
  }
}