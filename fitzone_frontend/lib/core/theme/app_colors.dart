import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFF0A0A0A);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF22D3EE);
  static const Color teal = Color(0xFF14B8A6);
  static const Color destructive = Color(0xFFEF4444);

  /// Cian (#06B6D4) con opacidad de 0.0 a 1.0.
  static Color cyanA(double opacity) => Color.fromRGBO(6, 182, 212, opacity);

  /// Turquesa (#14B8A6) con opacidad de 0.0 a 1.0.
  static Color tealA(double opacity) => Color.fromRGBO(20, 184, 166, opacity);

  /// Blanco con opacidad de 0.0 a 1.0.
  static Color whiteA(double opacity) => Color.fromRGBO(255, 255, 255, opacity);
}