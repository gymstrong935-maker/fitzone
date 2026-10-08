import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final ThemeData base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        onPrimary: AppColors.background,
        secondary: AppColors.teal,
        onSecondary: AppColors.background,
        surface: AppColors.background,
        error: AppColors.destructive,
      ),
      // Las fuentes (Exo 2 y Outfit) se aplican en cada texto con AppText.
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}