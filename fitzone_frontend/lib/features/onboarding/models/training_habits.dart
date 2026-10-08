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
  });

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
  }) {
    return TrainingHabits(
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      activityLevel: activityLevel ?? this.activityLevel,
      availability: availability ?? this.availability,
    );
  }
}