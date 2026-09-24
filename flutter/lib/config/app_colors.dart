import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1A1A1A);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF22D3EE);

  static const Color teal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFF2DD4BF);

  static const Color white = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);

  static const Color purple = Color(0xFFA855F7);
  static const Color pink = Color(0xFFEC4899);

  static const Color green = Color(0xFF22C55E);
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      cyan,
      teal,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [
      purple,
      pink,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}