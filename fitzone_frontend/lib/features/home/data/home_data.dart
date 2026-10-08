import 'package:flutter/material.dart';

import '../../onboarding/models/experience_level.dart';

const List<String> kHomeQuotes = <String>[
  'La disciplina es hacer lo que debe hacerse, aunque no quieras.',
  'Tu cuerpo puede soportar casi cualquier cosa. Es tu mente la que debes convencer.',
  'El único entrenamiento malo es el que no hiciste.',
  'No se trata de tener tiempo. Se trata de crearlo.',
  'El dolor de hoy es la fuerza de mañana.',
];

/// Letras de los días, de lunes a domingo.
const List<String> kWeekDays = <String>['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// Rutina que se muestra en "Rutina de hoy".
class TodayWorkout {
  const TodayWorkout({
    required this.name,
    required this.exercises,
    required this.duration,
  });

  final String name;
  final int exercises;

  /// Minutos.
  final int duration;
}

/// La rutina depende del nivel de experiencia (sin nivel = avanzado, igual que
/// el diseño).
TodayWorkout todayWorkoutFor(ExperienceLevel? level) {
  switch (level) {
    case ExperienceLevel.beginner:
      return const TodayWorkout(
        name: 'Fuerza Full Body',
        exercises: 6,
        duration: 40,
      );
    case ExperienceLevel.intermediate:
      return const TodayWorkout(
        name: 'Hipertrofia A/B',
        exercises: 8,
        duration: 55,
      );
    case ExperienceLevel.advanced:
    case null:
      return const TodayWorkout(
        name: 'Entrenamiento Avanzado',
        exercises: 10,
        duration: 70,
      );
  }
}

/// Acceso rápido (tarjeta con ícono en degradado).
class QuickAction {
  const QuickAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.from,
    required this.to,
  });

  /// Identificador de la pantalla a la que navega.
  final String id;
  final IconData icon;
  final String label;
  final Color from;
  final Color to;
}

const List<QuickAction> kQuickActions = <QuickAction>[
  QuickAction(
    id: 'history',
    icon: Icons.history_rounded,
    label: 'Historial',
    from: Color(0xFFA855F7), // morado
    to: Color(0xFFEC4899), // rosa
  ),
  QuickAction(
    id: 'nutrition',
    icon: Icons.restaurant_rounded,
    label: 'Nutrición',
    from: Color(0xFF22C55E), // verde
    to: Color(0xFF10B981), // esmeralda
  ),
  QuickAction(
    id: 'achievements',
    icon: Icons.emoji_events_outlined,
    label: 'Logros',
    from: Color(0xFFEAB308), // amarillo
    to: Color(0xFFF97316), // naranja
  ),
  QuickAction(
    id: 'community',
    icon: Icons.people_outline_rounded,
    label: 'Comunidad',
    from: Color(0xFF3B82F6), // azul
    to: Color(0xFF06B6D4), // cian
  ),
];