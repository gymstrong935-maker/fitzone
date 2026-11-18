/// Detalle técnico de un ejercicio (hoja "Ver técnica").
class ExerciseTechnique {
  const ExerciseTechnique({
    required this.muscles,
    required this.breathing,
    required this.steps,
    required this.errors,
  });

  final List<String> muscles;
  final String breathing;
  final List<String> steps;
  final List<String> errors;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.description,
    required this.muscleGroup,
    required this.equipment,
    required this.instructions,
    required this.technique,
  });

  final String id;
  final String name;
  final int sets;

  /// Rango de repeticiones, p. ej. "8-10".
  final String reps;

  /// Descanso en segundos.
  final int rest;
  final String description;
  final String muscleGroup;
  final List<String> equipment;
  final List<String> instructions;
  final ExerciseTechnique technique;
}