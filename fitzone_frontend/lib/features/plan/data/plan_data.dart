/// Un día del plan semanal.
class WeekWorkout {
  const WeekWorkout({
    required this.day,
    required this.short,
    required this.name,
    required this.duration,
    required this.exercises,
    required this.completed,
    required this.rest,
  });

  final String day;

  /// Letra del día (L, M, X, J, V, S, D).
  final String short;
  final String name;

  /// Minutos.
  final int duration;
  final int exercises;
  final bool completed;

  /// `true` = día de descanso (sin botones de acción).
  final bool rest;

  WeekWorkout copyWith({bool? completed}) {
    return WeekWorkout(
      day: day,
      short: short,
      name: name,
      duration: duration,
      exercises: exercises,
      completed: completed ?? this.completed,
      rest: rest,
    );
  }
}

const List<WeekWorkout> kWeekWorkouts = <WeekWorkout>[
  WeekWorkout(
    day: 'Lunes',
    short: 'L',
    name: 'Pecho y Tríceps',
    duration: 60,
    exercises: 8,
    completed: true,
    rest: false,
  ),
  WeekWorkout(
    day: 'Martes',
    short: 'M',
    name: 'Espalda y Bíceps',
    duration: 65,
    exercises: 9,
    completed: true,
    rest: false,
  ),
  WeekWorkout(
    day: 'Miércoles',
    short: 'X',
    name: 'Descanso Activo',
    duration: 30,
    exercises: 0,
    completed: false,
    rest: true,
  ),
  WeekWorkout(
    day: 'Jueves',
    short: 'J',
    name: 'Piernas',
    duration: 70,
    exercises: 10,
    completed: false,
    rest: false,
  ),
  WeekWorkout(
    day: 'Viernes',
    short: 'V',
    name: 'Hombros y Core',
    duration: 55,
    exercises: 8,
    completed: false,
    rest: false,
  ),
  WeekWorkout(
    day: 'Sábado',
    short: 'S',
    name: 'Cardio HIIT',
    duration: 30,
    exercises: 5,
    completed: false,
    rest: false,
  ),
  WeekWorkout(
    day: 'Domingo',
    short: 'D',
    name: 'Descanso',
    duration: 0,
    exercises: 0,
    completed: false,
    rest: true,
  ),
];

/// Ítem de "Recuperación y Bienestar".
class RecoveryItem {
  const RecoveryItem({
    required this.name,
    required this.duration,
    required this.icon,
    required this.description,
  });

  final String name;
  final String duration;

  /// Emoji.
  final String icon;
  final String description;
}

const List<RecoveryItem> kRecoveryItems = <RecoveryItem>[
  RecoveryItem(
    name: 'Estiramientos',
    duration: '10 min',
    icon: '🤸',
    description: 'Flexibilidad global',
  ),
  RecoveryItem(
    name: 'Movilidad',
    duration: '15 min',
    icon: '🔄',
    description: 'Articulaciones',
  ),
  RecoveryItem(
    name: 'Foam Roller',
    duration: '12 min',
    icon: '💆',
    description: 'Recuperación miofascial',
  ),
];

/// Ciclo de entrenamiento actual.
class Mesocycle {
  const Mesocycle({
    required this.phase,
    required this.currentWeek,
    required this.totalWeeks,
    required this.deloadWeek,
  });

  final String phase;
  final int currentWeek;
  final int totalWeeks;
  final int deloadWeek;

  /// Avance de 0.0 a 1.0.
  double get progress => currentWeek / totalWeeks;
}

const Mesocycle kMesocycle = Mesocycle(
  phase: 'Hipertrofia',
  currentWeek: 2,
  totalWeeks: 4,
  deloadWeek: 4,
);

/// Índice del día de hoy: lunes = 0 ... domingo = 6.
int todayWeekdayIndex() => DateTime.now().weekday - 1;