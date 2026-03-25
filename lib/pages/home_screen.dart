import 'package:flutter/material.dart';
import 'package:pro_tocol/presentation/controllers/SSHOrchestrator.dart';
import '../widgets/connection_dialog.dart';
import 'server_screen.dart';
import 'package:pro_tocol/presentation/controllers/NavigationController.dart';
import 'package:pro_tocol/presentation/controllers/ProfileController.dart';
import 'package:pro_tocol/entity/DataBaseEntities.dart';
import 'package:pro_tocol/entity/TempSession.dart';

class HomeScreen extends StatelessWidget {
  final String profileName;
  final ProfileController profileController;
  final NavigationController navigationController;
  final SSHOrchestrator sshOrchestrator;

  const HomeScreen({
    super.key,
    required this.profileName,
    required this.profileController,
    required this.navigationController,
    required this.sshOrchestrator
  });

  @override
  Widget build(BuildContext context) {
    // Escuchamos al controlador de navegación para redibujar el body y el AppBar
    return ListenableBuilder(
      listenable: navigationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F1319),
          drawer: _buildSidebar(context),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B2430),
            elevation: 0,
            title: Text(
              _getAppBarTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          // El cuerpo es dinámico: Welcome, Server View o Temp Session
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B2430), Color(0xFF000000)],
              ),
            ),
            child: _buildMainContent(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF0F1319),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF8B63FF),
            unselectedItemColor: Colors.white54,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notificaciones'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }

  // Decide qué mostrar en el centro de la pantalla
  Widget _buildMainContent() {
    switch (navigationController.currentView) {
      case ViewType.serverView:
        final server = navigationController.selectedServer!;
        return ServerScreen(
          serverName: server.config.host,
          connectionInfo: '${server.config.username}@${server.config.host}',
          isTemporarySession: false, orchestrator: sshOrchestrator,
        );
      case ViewType.tempSessionView:
        final session = navigationController.selectedTempSession!;
        return ServerScreen(
          serverName: 'Sesión Temporal',
          connectionInfo: '${session.username}@${session.host}',
          isTemporarySession: true, orchestrator: sshOrchestrator,
        );
      case ViewType.home:
      default:
        return _buildWelcomeView();
    }
  }

  String _getAppBarTitle() {
    if (navigationController.currentView == ViewType.serverView) return "Servidor";
    if (navigationController.currentView == ViewType.tempSessionView) return "Terminal";
    return "Inicio";
  }

  Widget _buildWelcomeView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF282A36),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(0xFF8B63FF),
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Perfil: $profileName',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Usa el menú lateral para gestionar\nservidores y sesiones',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR CONECTADO AL PROFILE CONTROLLER ---

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F1319),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: profileController,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebarHeader(context),
                const Divider(color: Colors.white10, height: 1),

                // SECCIÓN SERVIDORES (Persistencia Isar)
                _buildSectionHeader('Servidores', Icons.dns_outlined, () => _showServerDialog(context)),
                ...profileController.activeServers.map((server) => _buildSidebarItem(
                  title: server.config.host,
                  isActive: navigationController.selectedServer == server,
                  isSession: false,
                  subtitle: 'Online',
                  onTap: () {
                    navigationController.selectServer(server);
                    Navigator.pop(context);
                  },
                  onDelete: () => profileController.deleteServer(server),
                )),

                const SizedBox(height: 20),
                const Divider(color: Colors.white10, height: 1),

                // SECCIÓN SESIONES TEMPORALES (RAM)
                _buildSectionHeader('Sesiones Temporales', Icons.access_time, () => _showTempSessionDialog(context)),
                ...profileController.activeTempSessions.map((session) => _buildSidebarItem(
                  title: session.host,
                  isActive: navigationController.selectedTempSession == session,
                  isSession: true,
                  subtitle: 'Activa',
                  onTap: () {
                    navigationController.selectTempSession(session);
                    Navigator.pop(context);
                  },
                  onDelete: () {
                    profileController.removeTempSession(session);
                    if (navigationController.selectedTempSession == session) {
                      navigationController.goHome();
                    }
                  },
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- COMPONENTES VISUALES ---

  Widget _buildSidebarHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Menú', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
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
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white54, size: 20),
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
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF282A36) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          leading: isSession
              ? null
              : CircleAvatar(radius: 4, backgroundColor: isActive ? Colors.greenAccent : Colors.white24),
          title: Text(title, style: TextStyle(color: isActive ? const Color(0xFF8B63FF) : Colors.white, fontSize: 14)),
          subtitle: isSession || !isActive ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }

  // --- DIÁLOGOS DE CREACIÓN ---

  void _showServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConnectionFormDialog(
        title: 'Crear Servidor',
        subtitle: 'Se guardará en Isar y se conectará ahora',
        buttonText: 'Guardar y Conectar',
        onSubmit: (host, user, pass, port) async {
          // 1. Creamos el objeto de configuración
          final config = ServerConfig()
            ..host = host
            ..username = user
            ..password = pass
            ..port = port;

          // 2. ¡PASO CRUCIAL! Llamamos al orquestador para conectar REALMENTE
          // Mostramos un indicador de carga o simplemente esperamos
          String? error = await sshOrchestrator.connect(config);

          if (error == null) {
            // ÉXITO: Guardamos en la base de datos y navegamos
            await profileController.addServer(config);

            if (context.mounted) {
              Navigator.pop(context); // Cierra el diálogo
              // Seleccionamos el servidor para que la UI cambie a ServerScreen
              navigationController.selectServer(profileController.activeServers.last);
            }
          } else {
            // ERROR: Mostramos el error al usuario (puedes usar un SnackBar)
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
    );
  }

  void _showTempSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConnectionFormDialog(
        title: 'Nueva Sesión Temporal',
        subtitle: 'Los datos no se guardarán al cerrar la app',
        buttonText: 'Conectar Ahora',
        onSubmit: (host, user, pass, port) async {
          final newSession = TempSession(
            host: host,
            username: user,
            password: pass,
            port: port,
          );

          // Intentamos la conexión real antes de añadirlo a la RAM
          String? error = await sshOrchestrator.connect(newSession);

          if (error == null) {
            profileController.addTempSession(newSession);
            if (context.mounted) {
              Navigator.pop(context);
              navigationController.selectTempSession(newSession);
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
    );
  }
}