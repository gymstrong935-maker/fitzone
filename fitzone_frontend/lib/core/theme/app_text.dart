import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilos de texto de FitZone.
/// display = Exo 2 (títulos, precios) · body = Outfit (texto general).
class AppText {
  AppText._();

  static TextStyle display({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.exo2(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}