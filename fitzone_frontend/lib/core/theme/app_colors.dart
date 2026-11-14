import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Paleta de FitZone con modo oscuro y modo claro reales.
///
/// · Los colores de marca (cian / turquesa) son constantes.
/// · El resto son "tokens": cambian solos según el modo, así que se pueden usar
///   en cualquier `build` (no en contextos `const`).
class AppColors {
  AppColors._();

  static bool get isLight => ThemeController.instance.isLight;

  // ── Marca (iguales en ambos modos) ────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFF0A0A0A);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF22D3EE);
  static const Color teal = Color(0xFF14B8A6);
  static const Color destructive = Color(0xFFEF4444);

  /// Texto oscuro que va SOBRE botones y fichas de color de marca.
  static const Color onAccent = Color(0xFF0A0A0A);

  /// Cian (#06B6D4) con opacidad de 0.0 a 1.0.
  static Color cyanA(double opacity) => Color.fromRGBO(6, 182, 212, opacity);

  /// Turquesa (#14B8A6) con opacidad de 0.0 a 1.0.
  static Color tealA(double opacity) => Color.fromRGBO(20, 184, 166, opacity);

  // ── Superficies ───────────────────────────────────────────────────────────

  /// Fondo de pantalla (scaffold).
  static Color get bg => isLight ? const Color(0xFFF4F7FB) : const Color(0xFF000000);

  /// Tarjetas elevadas, diálogos, hojas inferiores y menús.
  static Color get surface =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F0F0F);

  /// Barras y hojas semitransparentes (nav inferior, sidebar...).
  static Color glass(double opacity) => isLight
      ? Color.fromRGBO(255, 255, 255, opacity)
      : Color.fromRGBO(8, 8, 8, opacity);

  /// Color principal del texto e iconos.
  static Color get ink =>
      isLight ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);

  /// "Blanco con opacidad" del diseño oscuro. En modo claro es la tinta oscura
  /// con la opacidad ajustada para que el texto siga siendo legible y las
  /// tarjetas / bordes se vean sutiles sobre el fondo claro.
  static Color whiteA(double opacity) {
    if (!isLight) return Color.fromRGBO(255, 255, 255, opacity);

    final double o = opacity.clamp(0.0, 1.0);
    final double a =
        o < 0.25 ? o * 1.1 : (0.275 + (o - 0.25) * 1.25).clamp(0.0, 1.0);
    return Color.fromRGBO(15, 23, 42, a);
  }

  // ── Degradados de fondo por pantalla ──────────────────────────────────────
  static List<Color> get authGradient => isLight
      ? const <Color>[Color(0xFFE3F3FA), Color(0xFFD7EEF7), Color(0xFFEAF5F9), Color(0xFFF4F8FB)]
      : const <Color>[Color(0xFF06111C), Color(0xFF071E2A), Color(0xFF050D13), Color(0xFF03080D)];

  static List<Color> get headerGradient => isLight
      ? const <Color>[Color(0xFFDDF1F8), Color(0xFFE1F6F1), Color(0xFFE6EEF9)]
      : const <Color>[Color(0xFF0A1628), Color(0xFF071E20), Color(0xFF0A0F1E)];

  // ── Acentos (más oscuros en modo claro para que tengan contraste) ─────────

  /// Cian para texto e iconos sobre el fondo.
  static Color get cyanText => isLight ? const Color(0xFF0E7490) : cyan;
  static Color get cyanLightText => isLight ? const Color(0xFF0891B2) : cyanLight;
  static Color get tealText => isLight ? const Color(0xFF0F766E) : teal;
  static Color get teal400 => isLight ? const Color(0xFF0D9488) : const Color(0xFF2DD4BF);

  static Color get red => isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171);
  static Color get redStrong => isLight ? const Color(0xFFB91C1C) : const Color(0xFFEF4444);
  static Color get green => isLight ? const Color(0xFF059669) : const Color(0xFF34D399);
  static Color get green400 => isLight ? const Color(0xFF16A34A) : const Color(0xFF4ADE80);
  static Color get greenStrong => isLight ? const Color(0xFF15803D) : const Color(0xFF22C55E);
  static Color get emerald => isLight ? const Color(0xFF047857) : const Color(0xFF10B981);
  static Color get amber => isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24);
  static Color get amberStrong => isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B);
  static Color get yellow => isLight ? const Color(0xFFA16207) : const Color(0xFFFACC15);
  static Color get yellowStrong => isLight ? const Color(0xFF854D0E) : const Color(0xFFEAB308);
  static Color get orange => isLight ? const Color(0xFFC2410C) : const Color(0xFFFB923C);
  static Color get orangeStrong => isLight ? const Color(0xFFEA580C) : const Color(0xFFF97316);
  static Color get violet => isLight ? const Color(0xFF6D28D9) : const Color(0xFFA78BFA);
  static Color get violetStrong => isLight ? const Color(0xFF7C3AED) : const Color(0xFFA855F7);
  static Color get purple => isLight ? const Color(0xFF7E22CE) : const Color(0xFFC084FC);
  static Color get purpleSoft => isLight ? const Color(0xFF9333EA) : const Color(0xFFD8B4FE);
  static Color get pink => isLight ? const Color(0xFFDB2777) : const Color(0xFFF472B6);
  static Color get pinkStrong => isLight ? const Color(0xFFBE185D) : const Color(0xFFEC4899);
  static Color get blue => isLight ? const Color(0xFF2563EB) : const Color(0xFF60A5FA);
  static Color get blueStrong => isLight ? const Color(0xFF1D4ED8) : const Color(0xFF3B82F6);
}
