import 'package:flutter/material.dart';
import 'package:pro_tocol/entity/ServerModel.dart';
import 'package:pro_tocol/entity/TempSession.dart';

// Definimos los tres estados posibles de la pantalla principal
enum ViewType { home, serverView, tempSessionView }

class NavigationController extends ChangeNotifier {
  ViewType currentView = ViewType.home;

  // Guardamos la referencia de qué ítem está seleccionado
  ServerModel? selectedServer;
  TempSession? selectedTempSession;

  /// Cambiar la vista principal para mostrar un Servidor Completo
  void selectServer(ServerModel server) {
    currentView = ViewType.serverView;
    selectedServer = server;
    selectedTempSession = null; // Limpiamos la otra selección
    notifyListeners();
  }

  /// Cambiar la vista principal para mostrar una Sesión Temporal
  void selectTempSession(TempSession session) {
    currentView = ViewType.tempSessionView;
    selectedTempSession = session;
    selectedServer = null; // Limpiamos la otra selección
    notifyListeners();
  }

  /// Volver a una pantalla por defecto (ej. al borrar la sesión activa)
  void goHome() {
    currentView = ViewType.home;
    selectedServer = null;
    selectedTempSession = null;
    notifyListeners();
  }
}