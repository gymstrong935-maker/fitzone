import '../../home/data/home_data.dart';
import '../../onboarding/models/experience_level.dart';
import '../../onboarding/models/goal.dart';
import '../../onboarding/models/onboarding_data.dart';
import '../../onboarding/models/training_habits.dart';
import '../../workout/data/routines_data.dart';
import '../../workout/models/exercise.dart';
import 'plan_data.dart';

const List<String> _dayNames = <String>[
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];
const List<String> _dayShort = <String>['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const int _mesocycleWeeks = 4;

/// Días de la semana (0 = lunes) que se entrena, según cuántos días son.
const Map<int, List<int>> _defaultDays = <int, List<int>>{
  1: <int>[2],
  2: <int>[0, 3],
  3: <int>[0, 2, 4],
  4: <int>[0, 1, 3, 4],
  5: <int>[0, 1, 3, 4, 5],
  6: <int>[0, 1, 2, 3, 4, 5],
};

/// Plan semanal personalizado con los datos del onboarding.
class TrainingPlan {
  const TrainingPlan({
    required this.week,
    required this.mesocycle,
    required this.days,
    required this.sessionsPerWeek,
    required this.summary,
  });

  /// 7 días (lunes a domingo) para la pantalla Mi Plan.
  final List<WeekWorkout> week;
  final Mesocycle mesocycle;

  /// Ejercicios de cada día (`null` = descanso).
  final List<List<Exercise>?> days;
  final int sessionsPerWeek;

  /// Ej. "Hipertrofia · 4 días por semana · 60 min".
  final String summary;

  bool isTrainingDay(DateTime date) => days[date.weekday - 1] != null;

  int _indexOfNextTraining(DateTime date) {
    for (int k = 0; k < 7; k++) {
      final int i = (date.weekday - 1 + k) % 7;
      if (days[i] != null) return i;
    }
    return -1;
  }

  /// Ejercicios que se harán hoy (o los del próximo día de entrenamiento).
  List<Exercise> workoutFor(DateTime date) {
    final int i = _indexOfNextTraining(date);
    return i < 0 ? const <Exercise>[] : days[i]!;
  }

  /// Datos para la tarjeta "Rutina de hoy" de Inicio.
  TodayWorkout todayWorkout(DateTime date) {
    final int i = _indexOfNextTraining(date);
    if (i < 0) {
      return const TodayWorkout(name: 'Sin rutina', exercises: 0, duration: 0);
    }
    final WeekWorkout w = week[i];
    final bool today = i == date.weekday - 1;
    return TodayWorkout(
      name: today ? w.name : 'Hoy descansas · adelanta ${w.name}',
      exercises: w.exercises,
      duration: w.duration,
    );
  }
}

TrainingPlan generatePlan(OnboardingData data, {DateTime? since}) {
  final Goal? goal = data.goal;
  final ExperienceLevel? level = data.experienceLevel;
  final TrainingHabits habits = data.trainingHabits;

  final List<int> trainingDays = _trainingDays(habits);
  final List<WorkoutRoutine> split = _split(trainingDays.length, _cardioBias(goal));

  final List<List<Exercise>?> days = List<List<Exercise>?>.filled(7, null);
  final List<WeekWorkout> week = <WeekWorkout>[];
  int totalMinutes = 0;

  for (int d = 0; d < 7; d++) {
    final int slot = trainingDays.indexOf(d);

    if (slot < 0) {
      week.add(
        WeekWorkout(
          day: _dayNames[d],
          short: _dayShort[d],
          name: 'Descanso Activo',
          duration: 30,
          exercises: 0,
          completed: false,
          rest: true,
        ),
      );
      continue;
    }

    final WorkoutRoutine routine = split[slot];
    final List<Exercise> prescribed = <Exercise>[
      for (final Exercise e in routine.exercises) _prescribe(e, goal, level),
    ];
    final List<Exercise> fitted = _fitToDuration(prescribed, habits.duration);
    final int minutes = _sessionMinutes(fitted);

    days[d] = fitted;
    totalMinutes += minutes;
    week.add(
      WeekWorkout(
        day: _dayNames[d],
        short: _dayShort[d],
        name: routine.name,
        duration: minutes,
        exercises: fitted.length,
        completed: false,
        rest: false,
      ),
    );
  }

  final Mesocycle mesocycle = _mesocycle(goal, since ?? DateTime.now());
  final int avg = trainingDays.isEmpty ? 0 : (totalMinutes / trainingDays.length).round();

  return TrainingPlan(
    week: week,
    mesocycle: mesocycle,
    days: days,
    sessionsPerWeek: trainingDays.length,
    summary:
        '${mesocycle.phase} · ${trainingDays.length} ${trainingDays.length == 1 ? 'día' : 'días'} por semana · $avg min',
  );
}

// ─── Días y rutinas ──────────────────────────────────────────────────────────

int? _weekdayIndex(String raw) {
  final String s = raw
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  if (s.length < 3) return null;
  const Map<String, int> keys = <String, int>{
    'lun': 0, 'mar': 1, 'mie': 2, 'jue': 3, 'vie': 4, 'sab': 5, 'dom': 6,
  };
  return keys[s.substring(0, 3)];
}

List<int> _trainingDays(TrainingHabits habits) {
  final int n = habits.frequency.clamp(1, 6);

  final List<int> chosen = <int>[];
  for (final String raw in habits.availability) {
    final int? i = _weekdayIndex(raw);
    if (i != null && !chosen.contains(i)) chosen.add(i);
  }
  chosen.sort();

  if (chosen.length >= n) return chosen.sublist(0, n);
  return _defaultDays[n]!;
}

bool _cardioBias(Goal? goal) =>
    goal == Goal.loseWeight || goal == Goal.improveEndurance;

List<WorkoutRoutine> _split(int days, bool cardio) {
  switch (days) {
    case 1:
      return <WorkoutRoutine>[kRoutineFullBody];
    case 2:
      return cardio
          ? <WorkoutRoutine>[kRoutineFullBody, kRoutineCardioCore]
          : <WorkoutRoutine>[kRoutineFullBody, kRoutineFullBody];
    case 3:
      return cardio
          ? <WorkoutRoutine>[kRoutineFullBody, kRoutineCardioCore, kRoutineLegsGlutes]
          : <WorkoutRoutine>[kRoutineFullBody, kRoutineLegsGlutes, kRoutineUpperBody];
    case 4:
      return cardio
          ? <WorkoutRoutine>[kRoutineFullBody, kRoutineCardioCore, kRoutineLegsGlutes, kRoutineUpperBody]
          : <WorkoutRoutine>[kRoutineChestTriceps, kRoutineLegsGlutes, kRoutineBackBiceps, kRoutineShouldersCore];
    case 5:
      return cardio
          ? <WorkoutRoutine>[kRoutineFullBody, kRoutineCardioCore, kRoutineLegsGlutes, kRoutineUpperBody, kRoutineCardioCore]
          : <WorkoutRoutine>[kRoutineChestTriceps, kRoutineBackBiceps, kRoutineLegsGlutes, kRoutineShouldersCore, kRoutineFullBody];
    default:
      return cardio
          ? <WorkoutRoutine>[kRoutineFullBody, kRoutineCardioCore, kRoutineLegsGlutes, kRoutineUpperBody, kRoutineCardioCore, kRoutineFullBody]
          : <WorkoutRoutine>[kRoutineChestTriceps, kRoutineBackBiceps, kRoutineLegsGlutes, kRoutineShouldersCore, kRoutineFullBody, kRoutineCardioCore];
  }
}

// ─── Series, repeticiones y descansos ────────────────────────────────────────

Exercise _prescribe(Exercise e, Goal? goal, ExperienceLevel? level) {
  final bool timed = RegExp(r'\d\s*s$').hasMatch(e.reps.trim());
  final bool perLeg = e.reps.contains('por pierna');
  final bool fixedReps = timed ||
      perLeg ||
      e.muscleGroup == 'Core' ||
      e.muscleGroup == 'Pantorrillas' ||
      e.muscleGroup == 'Cardio';

  String reps = e.reps;
  double restFactor = 1;

  switch (goal) {
    case Goal.gainMuscle:
      if (!fixedReps) reps = '8-12';
    case Goal.bodyRecomposition:
      if (!fixedReps) reps = '10-12';
      restFactor = 0.9;
    case Goal.loseWeight:
      if (!fixedReps) reps = '12-15';
      restFactor = 0.7;
    case Goal.improveEndurance:
      if (!fixedReps) reps = '15-20';
      restFactor = 0.55;
    case Goal.athleticPerformance:
      if (!fixedReps) reps = '5-8';
      restFactor = 1.3;
    case null:
      break;
  }

  int sets = e.sets;
  if (level == ExperienceLevel.beginner && sets > 3) sets = 3;
  if (level == ExperienceLevel.advanced && sets < 5) sets += 1;

  final int rest = ((e.rest * restFactor) / 5).round() * 5;

  return Exercise(
    id: e.id,
    name: e.name,
    sets: sets,
    reps: reps,
    rest: rest < 20 ? 20 : rest,
    description: e.description,
    muscleGroup: e.muscleGroup,
    equipment: e.equipment,
    instructions: e.instructions,
    technique: e.technique,
  );
}

// ─── Duración ────────────────────────────────────────────────────────────────

int _minutesFor(Exercise e) =>
    (e.sets * 0.8 + e.rest * (e.sets - 1) / 60 + 1).ceil();

List<Exercise> _fitToDuration(List<Exercise> list, int target) {
  final List<Exercise> out = <Exercise>[];
  int total = 0;
  for (final Exercise e in list) {
    final int m = _minutesFor(e);
    if (out.length >= 3 && total + m > target) break;
    out.add(e);
    total += m;
  }
  return out;
}

int _sessionMinutes(List<Exercise> list) {
  int total = 5; // calentamiento
  for (final Exercise e in list) {
    total += _minutesFor(e);
  }
  final int rounded = (total / 5).round() * 5;
  return rounded < 15 ? 15 : rounded;
}

// ─── Mesociclo ───────────────────────────────────────────────────────────────

Mesocycle _mesocycle(Goal? goal, DateTime since) {
  final String phase = switch (goal) {
    Goal.gainMuscle => 'Hipertrofia',
    Goal.loseWeight => 'Definición',
    Goal.improveEndurance => 'Resistencia',
    Goal.bodyRecomposition => 'Recomposición',
    Goal.athleticPerformance => 'Rendimiento',
    null => 'General',
  };

  final int weeksSince = DateTime.now().difference(since).inDays ~/ 7;
  final int current = (weeksSince % _mesocycleWeeks) + 1;

  return Mesocycle(
    phase: phase,
    currentWeek: current,
    totalWeeks: _mesocycleWeeks,
    deloadWeek: _mesocycleWeeks,
  );
}