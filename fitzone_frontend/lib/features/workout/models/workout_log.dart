enum FatigueLevel { none, moderate, fatigued, high, veryHigh }

enum SorenessLevel { none, light, moderate, intense }

/// Registro de un entrenamiento terminado.
class WorkoutLog {
  const WorkoutLog({
    required this.workoutId,
    required this.date,
    required this.duration,
    required this.fatigue,
    required this.soreness,
    this.restingHeartRate,
  });

  final String workoutId;
  final DateTime date;

  /// Minutos.
  final int duration;
  final int? restingHeartRate;
  final FatigueLevel fatigue;
  final SorenessLevel soreness;
}