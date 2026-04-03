import 'package:flutter/material.dart';

import 'package:pro_tocol/controller/NavigationController.dart';
import 'package:pro_tocol/controller/ProfileController3.dart';
import 'package:pro_tocol/controller/SSHOrchestrator.dart';
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';
import 'package:pro_tocol/model/entities/TempSession.dart';
import 'package:pro_tocol/view/components/connection_dialog.dart';
import 'ErrorConnectionScreen.dart';
import 'server_screen.dart';

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
    return ListenableBuilder(
      listenable: navigationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F1319),
          drawer: _buildSidebar(context),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B2430),
            elevation: 0,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getAppBarTitle(),
                key: ValueKey<String>(_getAppBarTitle()), 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B2430), Color(0xFF000000)],
              ),
            ),
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
            backgroundColor: const Color(0xFF0F1319),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF8B63FF),
            unselectedItemColor: Colors.white54,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    switch (navigationController.currentView) {
      case ViewType.serverView:
        final server = navigationController.selectedServer!;
        return ServerScreen(
          key: const ValueKey('server_view'), 
          serverName: server.config.host,
          connectionInfo: '${server.config.username}@${server.config.host}',
          isTemporarySession: false, orchestrator: sshOrchestrator,
        );
      case ViewType.tempSessionView:
        final session = navigationController.selectedTempSession!;
        return ServerScreen(
          key: const ValueKey('temp_session_view'), 
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
      key: const ValueKey('welcome_view'), 
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

  // --- MÉTODO PARA CONFIRMAR ELIMINACIÓN ---
  void _confirmDelete(BuildContext context, String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151821),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
        title: const Text('¿Eliminar conexión?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar "$itemName"? Esta acción no se puede deshacer.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              onConfirm(); // Ejecuta la eliminación
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  onEdit: () {
                    Navigator.pop(context);
                    _showEditServerDialog(context, server); 
                  },
                  onDelete: () {
                    _confirmDelete(context, server.config.host, () {
                      profileController.deleteServer(server);
                      if (navigationController.selectedServer == server) {
                        navigationController.goHome();
                      }
                    });
                  },
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
                  onEdit: () {
                    Navigator.pop(context);
                    _showEditTempSessionDialog(context, session); 
                  },
                  onDelete: () {
                    _confirmDelete(context, session.host, () {
                      profileController.removeTempSession(session);
                      if (navigationController.selectedTempSession == session) {
                        navigationController.goHome();
                      }
                    });
                  },
                )),
              ],
            );
          },
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
    required VoidCallback onEdit,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIÁLOGOS DE CREACIÓN Y EDICIÓN ---

  void _showServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConnectionFormDialog( // Cambié el nombre a dialogContext para evitar confusiones
        title: 'Crear Servidor',
        subtitle: 'Se guardará en Isar y se conectará ahora',
        buttonText: 'Guardar y Conectar',
        onSubmit: (host, user, pass, port) async {
          final config = ServerConfig()
            ..host = host
            ..username = user
            ..password = pass
            ..port = port;

          // Definimos la función de intento
          Future<void> intentarConexion() async {
            String? error = await sshOrchestrator.connect(config);

            if (error == null) {
              await profileController.addServer(config);
              if (context.mounted) {
                // Cerramos el diálogo y navegamos al home/servidor
                Navigator.of(dialogContext).pop();
                navigationController.selectServer(profileController.activeServers.last);
              }
            } else {
              if (context.mounted) {
                // Si falla, vamos a la pantalla de error
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SshErrorDisplay(
                      errorMessage: error,
                      onRetry: () => intentarConexion(), // Ajuste de VoidCallback
                    ),
                  ),
                );
              }
            }
          }

          await intentarConexion();
        },
      ),
    );
  }

  // DIÁLOGO PARA EDITAR SERVIDOR CONECTADO A ISAR
  void _showEditServerDialog(BuildContext context, dynamic server) {
    showDialog(
      context: context,
      builder: (context) => ConnectionFormDialog(
        title: 'Editar Servidor',
        subtitle: 'Actualiza los datos de conexión',
        buttonText: 'Guardar Cambios',
        initialHost: server.config.host,
        initialUser: server.config.username,
        initialPass: server.config.password,
        onSubmit: (host, user, pass, port) async {
          // 1. Actualizamos los datos en memoria del objeto Isar
          server.config.host = host;
          server.config.username = user;
          server.config.password = pass;
          server.config.port = port;

          // 2. Guardamos en la base de datos Isar de forma permanente
          await profileController.updateServer(server.config); 
          
          // 3. Cerramos el formulario si todo salió bien
          if (context.mounted) Navigator.pop(context);
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

          Future<void> intentarConexionTemporal() async {
            String? error = await sshOrchestrator.connect(newSession);

            if (error == null) {
              profileController.addTempSession(newSession);
              if (context.mounted) {
                Navigator.pop(context); 
                navigationController.selectTempSession(newSession);
              }
            } else {
              if (context.mounted) {
                // Si falla, vamos a la pantalla de error
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SshErrorDisplay(
                      errorMessage: error,
                      onRetry: () => intentarConexionTemporal(), // Ajuste de VoidCallback
                    ),
                  ),
                );
              }
            }
          }

          await intentarConexionTemporal();
        },
      ),
    );
  }

// DIÁLOGO PARA EDITAR SESIÓN TEMPORAL (Solo en RAM)
  void _showEditTempSessionDialog(BuildContext context, TempSession session) {
    showDialog(
      context: context,
      builder: (context) => ConnectionFormDialog(
        title: 'Editar Sesión Temporal',
        subtitle: 'Actualiza los datos para esta sesión',
        buttonText: 'Actualizar',
        initialHost: session.host,
        initialUser: session.username,
        initialPass: session.password,
        onSubmit: (host, user, pass, port) {
          
          // 1. Creamos una nueva sesión con los datos fresquitos
          final updatedSession = TempSession(
            host: host,
            username: user,
            password: pass,
            port: port,
          );
          
          // 2. Borramos la vieja y metemos la nueva en el controlador
          profileController.removeTempSession(session);
          profileController.addTempSession(updatedSession);
          
          // 3. Si estábamos visualizando esa sesión, actualizamos el panel
          if (navigationController.selectedTempSession == session) {
            navigationController.selectTempSession(updatedSession);
          }

          // 4. Cerramos el formulario
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
