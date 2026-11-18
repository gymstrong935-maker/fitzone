/// Un entrenamiento realizado.
class WorkoutEntry {
  const WorkoutEntry({
    required this.date,
    required this.name,
    required this.duration,
    required this.calories,
    required this.exercises,
  });

  final DateTime date;
  final String name;

  /// Minutos.
  final int duration;
  final int calories;
  final int exercises;
}

/// Entrenamientos de ejemplo (los mismos del diseño).
final List<WorkoutEntry> kWorkoutHistory = <WorkoutEntry>[
  WorkoutEntry(
    date: DateTime(2026, 9, 26),
    name: 'Pecho y Tríceps',
    duration: 58,
    calories: 450,
    exercises: 8,
  ),
  WorkoutEntry(
    date: DateTime(2026, 9, 25),
    name: 'Espalda y Bíceps',
    duration: 62,
    calories: 480,
    exercises: 9,
  ),
  WorkoutEntry(
    date: DateTime(2026, 9, 23),
    name: 'Piernas',
    duration: 68,
    calories: 520,
    exercises: 10,
  ),
  WorkoutEntry(
    date: DateTime(2026, 9, 22),
    name: 'Hombros',
    duration: 52,
    calories: 400,
    exercises: 8,
  ),
  WorkoutEntry(
    date: DateTime(2026, 9, 20),
    name: 'Full Body',
    duration: 72,
    calories: 550,
    exercises: 10,
  ),
];

const List<String> _weekdays = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const List<String> _months = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic',
];

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Sábado, 26 Sept"
String formatWorkoutDate(DateTime date) {
  final String weekday = _capitalize(_weekdays[date.weekday - 1]);
  final String month = _capitalize(_months[date.month - 1]);
  return '$weekday, ${date.day} $month';
}