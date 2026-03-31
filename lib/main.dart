import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Importaciones de tus entidades y controladores
import 'package:pro_tocol/entity/DataBaseEntities.dart';
import 'package:pro_tocol/presentation/controllers/ProfileController.dart';
import 'package:pro_tocol/presentation/controllers/NavigationController.dart';
import 'package:pro_tocol/pages/profile_screen.dart';
import 'package:pro_tocol/presentation/controllers/SSHOrchestrator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [ProfileSchema, ServerConfigSchema],
    directory: dir.path,
  );

  // 4. Instanciamos los controladores (nuestro "cerebro" global)
  final profileController = ProfileController(isar: isar);
  final navigationController = NavigationController();
  final sshOrchestrator = SSHOrchestrator();

  // 5. Corremos la App pasando los controladores por constructor
  runApp(MyApp(
    profileController: profileController,
    navigationController: navigationController,
    sshOrchestrator: sshOrchestrator,
  ));
}

class MyApp extends StatelessWidget {
  final ProfileController profileController;
  final NavigationController navigationController;
  final SSHOrchestrator sshOrchestrator;

  const MyApp({
    super.key,
    required this.profileController,
    required this.navigationController,
    required this.sshOrchestrator
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Perfiles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B63FF),
          brightness: Brightness.dark, 
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1319), 
        canvasColor: const Color(0xFF0F1319), 
        useMaterial3: true,
      ),
      home: ProfileScreen(
        controller: profileController,
        navigationController: navigationController,
        sshOrchestrator: sshOrchestrator,
      ),
    );
  }
}


class SmoothFadeRoute extends PageRouteBuilder {
  final Widget page;
  
  SmoothFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}