
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// --- Entidades ---
import 'package:pro_tocol/model/entities/DataBaseEntities.dart';

// --- DAOs ---
import 'package:pro_tocol/model/daos/ProfileDAO.dart';
import 'package:pro_tocol/model/daos/ServerConfigDAO.dart';

// --- Repositorios ---
import 'package:pro_tocol/model/repositories/ProfileRepository.dart';
import 'package:pro_tocol/model/repositories/ServerRepository.dart';

// --- Controladores ---
import 'package:pro_tocol/controller/ProfileController.dart';
import 'package:pro_tocol/controller/ServerController.dart';
import 'package:pro_tocol/view/pages/ProfilePage.dart';
import 'package:pro_tocol/view/theme/AppColors.dart';

// --- Vistas ---


void main() async {
  // 1. Asegurar que los bindings de Flutter estén listos antes de ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Isar Database
  // Necesitamos una ruta segura en el dispositivo para guardar los datos
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [ProfileSchema, ServerConfigSchema], // Esquemas generados por build_runner
    directory: dir.path,
  );

  // 3. Inyección de Dependencias (Manual)
  // Construimos las capas de abajo hacia arriba

  // a. Capa de Acceso a Datos
  final profileDAO = ProfileDAO(isar);
  final serverConfigDAO = ServerConfigDAO(isar);

  // b. Capa de Repositorios
  final profileRepository = ProfileRepository(profileDAO);
  final serverRepository = ServerRepository(serverConfigDAO);

  // c. Capa de Controladores (Reglas de negocio y estado en memoria)
  final profileController = ProfileController(profileRepository);
  final serverController = ServerController(serverRepository, profileRepository);

  // 4. Arrancar la aplicación inyectando los controladores en la raíz
  runApp(MyApp(
    profileController: profileController,
    serverController: serverController,
  ));
}

class MyApp extends StatelessWidget {
  final ProfileController profileController;
  final ServerController serverController;

  const MyApp({
    Key? key,
    required this.profileController,
    required this.serverController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro-Tocol SSH',
      debugShowCheckedModeBanner: false,
      // Iniciamos directamente en la página de perfiles
      home: ProfilePage(
        profileController: profileController,
        serverController: serverController,
      ),
    );
  }
}