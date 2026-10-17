import '../../onboarding/models/experience_level.dart';
import '../models/exercise.dart';
import 'exercises_data.dart';

/// Rutina del día: un grupo de ejercicios de la biblioteca.
class WorkoutRoutine {
  const WorkoutRoutine({required this.name, required this.exerciseIds});

  final String name;
  final List<String> exerciseIds;

  /// Ejercicios de la rutina según el nivel (principiante 5, intermedio 6,
  /// avanzado todos).
  List<Exercise> exercisesFor(ExperienceLevel? level) {
    final Map<String, Exercise> byId = <String, Exercise>{
      for (final Exercise e in kExercises) e.id: e,
    };
    final List<Exercise> all = <Exercise>[
      for (final String id in exerciseIds)
        if (byId[id] != null) byId[id]!,
    ];

    final int max = switch (level) {
      ExperienceLevel.beginner => 5,
      ExperienceLevel.intermediate => 6,
      _ => 8,
    };
    return all.length > max ? all.sublist(0, max) : all;
  }
}

const WorkoutRoutine _chestTriceps = WorkoutRoutine(
  name: 'Pecho y Tríceps',
  exerciseIds: <String>['ex-1', 'ex-8', 'ex-7', 'ex-12', 'ex-14'],
);
const WorkoutRoutine _backBiceps = WorkoutRoutine(
  name: 'Espalda y Bíceps',
  exerciseIds: <String>['ex-5', 'ex-10', 'ex-4', 'ex-6', 'ex-13'],
);
const WorkoutRoutine _legsGlutes = WorkoutRoutine(
  name: 'Piernas y Glúteos',
  exerciseIds: <String>['ex-2', 'ex-9', 'ex-4', 'ex-15', 'ex-16'],
);
const WorkoutRoutine _shouldersCore = WorkoutRoutine(
  name: 'Hombros y Core',
  exerciseIds: <String>['ex-3', 'ex-11', 'ex-14', 'ex-13', 'ex-17'],
);
const WorkoutRoutine _fullBody = WorkoutRoutine(
  name: 'Cuerpo Completo',
  exerciseIds: <String>['ex-2', 'ex-1', 'ex-5', 'ex-3', 'ex-9', 'ex-14'],
);
const WorkoutRoutine _cardioCore = WorkoutRoutine(
  name: 'Cardio y Core',
  exerciseIds: <String>['ex-18', 'ex-17', 'ex-8', 'ex-9', 'ex-13', 'ex-14'],
);

/// Lunes a domingo.
const List<WorkoutRoutine> kWeekRoutines = <WorkoutRoutine>[
  _chestTriceps,
  _backBiceps,
  _legsGlutes,
  _shouldersCore,
  _fullBody,
  _cardioCore,
  _cardioCore,
];

/// La rutina que toca en una fecha.
WorkoutRoutine routineForDate(DateTime date) => kWeekRoutines[date.weekday - 1];

/// Duración aproximada (minutos, redondeada de 5 en 5).
int estimateMinutes(List<Exercise> exercises) {
  double minutes = 0;
  for (final Exercise e in exercises) {
    minutes += e.sets * 0.8 + e.rest * (e.sets - 1) / 60;
  }
  final int rounded = (minutes / 5).round() * 5;
  return rounded < 10 ? 10 : rounded;
}