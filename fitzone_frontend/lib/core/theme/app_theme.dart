import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(light: false);
  static ThemeData get light => _build(light: true);

  static ThemeData _build({required bool light}) {
    final Brightness brightness = light ? Brightness.light : Brightness.dark;
    final ThemeData base = ThemeData(brightness: brightness, useMaterial3: true);

    final Color ink = light ? const Color(0xFF0F172A) : Colors.white;
    final Color bg = light ? const Color(0xFFF4F7FB) : Colors.black;
    final Color surface = light ? Colors.white : const Color(0xFF0F0F0F);

    final ColorScheme scheme = light
        ? const ColorScheme.light(
            primary: AppColors.cyan,
            onPrimary: AppColors.onAccent,
            secondary: AppColors.teal,
            onSecondary: AppColors.onAccent,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
            error: AppColors.destructive,
          )
        : const ColorScheme.dark(
            primary: AppColors.cyan,
            onPrimary: AppColors.onAccent,
            secondary: AppColors.teal,
            onSecondary: AppColors.onAccent,
            surface: AppColors.background,
            error: AppColors.destructive,
          );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      canvasColor: surface,
      dialogTheme: DialogThemeData(backgroundColor: surface),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: AppColors.cyan.withValues(alpha: 0.30),
        selectionHandleColor: AppColors.cyan,
      ),
      // Las fuentes (Exo 2 y Outfit) se aplican en cada texto con AppText.
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    );
  }
}
