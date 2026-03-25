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
  // 1. Aseguramos que los bindings de Flutter estén listos para procesos asíncronos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configuramos la ruta de almacenamiento para Isar
  final dir = await getApplicationDocumentsDirectory();

  // 3. Abrimos la base de datos con los esquemas de Perfil y Configuración de Servidor
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

  // El constructor ya no es 'const' porque recibe objetos que se crean en tiempo de ejecución
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B63FF)),
        useMaterial3: true,
      ),
      // 6. Inyectamos los controladores en la pantalla de entrada
      home: ProfileScreen(
        controller: profileController,
        navigationController: navigationController,
        sshOrchestrator: sshOrchestrator,
      ),
    );
  }
}