
import 'package:flutter/material.dart';

class AppColors {
  // Paleta principal
  static const Color primary = Color(0xFF8B63FF);
  static const Color background = Color(0xFF0F1319);
  static const Color surface = Color(0xFF1B2430);
  static const Color surfaceHighlight = Color(0xFF282A36);

  // Fondos de diálogos
  static const Color dialogDark = Color(0xFF151821);
  static const Color dialogLight = Color(0xFFFEF7F7);

  // Terminal
  static const Color terminalBg = Colors.black;

  // Gradiente general
  static const Color gradientTop = Color(0xFF1B2430);
  static const Color gradientBottom = Color(0xFF000000);

  // Textos
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color textDark = Colors.black87;

  // Estados y Bordes
  static const Color error = Colors.redAccent;
  static const Color success = Colors.greenAccent;
  static const Color border = Colors.white10;

  // Iconos de Archivos (SFTP)
  static const Color fileDir = Color(0xFF8B63FF);
  static const Color fileTxt = Colors.blueAccent;
  static const Color fileImg = Colors.purpleAccent;
  static const Color fileCfg = Colors.orangeAccent;
}

class AppTheme {
  /// Gradiente global usado en los fondos de pantalla
  static BoxDecoration get mainBackground => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.gradientTop, AppColors.gradientBottom],
    ),
  );

  /// Estilo de tarjeta de vidrio oscuro (usado en modales y paneles)
  static BoxDecoration get glassCard => BoxDecoration(
    color: AppColors.surfaceHighlight,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
  );

  /// Estilo para campos de texto claros (como en el dialog de perfil)
  static InputDecoration lightInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none
      ),
    );
  }
}