
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Estilo VS Code
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF252526),
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF252526),
      ),
    );
  }
}