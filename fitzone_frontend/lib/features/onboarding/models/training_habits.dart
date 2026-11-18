enum SleepQuality {
  poor('poor'),
  fair('fair'),
  good('good'),
  excellent('excellent');

  const SleepQuality(this.apiValue);

  final String apiValue;
}

enum ActivityLevel {
  sedentary('sedentary'),
  light('light'),
  moderate('moderate'),
  active('active'),
  veryActive('very-active');

  const ActivityLevel(this.apiValue);

  final String apiValue;
}

/// Datos del paso "Hábitos de Entrenamiento" (con los mismos valores por
/// defecto que el diseño).
class TrainingHabits {
  const TrainingHabits({
    this.frequency = 3,
    this.duration = 60,
    this.sleepQuality = SleepQuality.good,
    this.sleepDuration = 7,
    this.activityLevel = ActivityLevel.moderate,
    this.availability = const <String>[],
    this.touched = const <String>{},
  });

  static const String kFrequency = 'frequency';
  static const String kDuration = 'duration';
  static const String kSleepQuality = 'sleepQuality';
  static const String kSleepDuration = 'sleepDuration';
  static const String kActivity = 'activity';
  static const Set<String> allTouched = <String>{
    kFrequency, kDuration, kSleepQuality, kSleepDuration, kActivity,
  };

  /// Controles que la persona ya confirmó.
  final Set<String> touched;

  List<String> get missing => <String>[
        if (!touched.contains(kFrequency)) 'frecuencia semanal',
        if (!touched.contains(kDuration)) 'duración por sesión',
        if (!touched.contains(kSleepQuality)) 'calidad del sueño',
        if (!touched.contains(kSleepDuration)) 'horas de sueño',
        if (!touched.contains(kActivity)) 'nivel de actividad',
      ];

  bool get isComplete => missing.isEmpty;

  TrainingHabits withTouched(String key) =>
      copyWith(touched: <String>{...touched, key});


  /// Días de entrenamiento por semana (1 a 7).
  final int frequency;

  /// Minutos por sesión (30 a 120, de 15 en 15).
  final int duration;
  final SleepQuality sleepQuality;

  /// Horas de sueño (4 a 12, de 0.5 en 0.5).
  final double sleepDuration;
  final ActivityLevel activityLevel;

  /// Reservado: el diseño lo tiene en los datos pero no lo muestra aún.
  final List<String> availability;

  TrainingHabits copyWith({
    int? frequency,
    int? duration,
    SleepQuality? sleepQuality,
    double? sleepDuration,
    ActivityLevel? activityLevel,
    List<String>? availability,
    Set<String>? touched,
  }) {
    return TrainingHabits(
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      activityLevel: activityLevel ?? this.activityLevel,
      availability: availability ?? this.availability,
      touched: touched ?? this.touched,
    );
  }
}