
import 'package:flutter/material.dart';

class AppTheme {
  // Theme Colors (Back to Blue)
  static const Color primaryColor = Colors.blueAccent;
  static const Color secondaryColor = Color(0xFF64B5F6); // Lighter Blue
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color infoColor = Colors.cyanAccent;
  static const Color complementaryColor = Colors.indigoAccent;

  // Macro Colors (Back to Blue/Teal/Indigo)
  static const Color proteinColor = Colors.blue;
  static const Color carbsColor = Colors.lightBlue;
  static const Color fatColor = Colors.indigo;
  static const Color waterColor = Colors.cyan;
  static const Color calorieColor = Colors.blueAccent;
  
  // Background Colors for Macro Boxes
  static Color macroBg(Color source) => source.withOpacity(0.08);
  static Color macroBorder(Color source) => source.withOpacity(0.15);

  // Status Colors
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.redAccent;
  
  // Shared Styles (Keeping the "Cute" rounded shapes)
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(32));
  static const BorderRadius innerRadius = BorderRadius.all(Radius.circular(20));
  
  static List<BoxShadow> softShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    )
  ];
}
