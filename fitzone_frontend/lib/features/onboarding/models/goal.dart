import 'package:flutter/material.dart';

/// Objetivo principal del usuario.
/// `apiValue` es el texto que usa el diseño (útil cuando conectemos el backend).
enum Goal {
  loseWeight('lose-weight'),
  gainMuscle('gain-muscle'),
  improveEndurance('improve-endurance'),
  bodyRecomposition('body-recomposition'),
  athleticPerformance('athletic-performance');

  const Goal(this.apiValue);

  final String apiValue;
}

/// Datos de presentación de un objetivo (tarjeta).
class GoalOption {
  const GoalOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.from,
    required this.to,
  });

  final Goal id;
  final String title;
  final String description;

  /// Emoji que se muestra dentro del círculo.
  final String icon;

  /// Colores del degradado del círculo (de arriba-izquierda a abajo-derecha).
  final Color from;
  final Color to;
}