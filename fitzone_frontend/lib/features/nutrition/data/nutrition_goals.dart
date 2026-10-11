import 'dart:math' as math;

import '../../onboarding/models/experience_level.dart';
import '../../onboarding/models/goal.dart';
import '../../onboarding/models/onboarding_data.dart';
import '../../onboarding/models/personal_info.dart';
import '../../onboarding/models/training_habits.dart';
import '../models/nutrition_models.dart';

/// Metas diarias de calorías y macros a partir de los datos del onboarding.
///
/// 1. Metabolismo basal (Mifflin-St Jeor):
///    10 × peso(kg) + 6.25 × estatura(cm) − 5 × edad + (hombre +5, mujer −161).
/// 2. Gasto diario = basal × factor de actividad (1.2 sedentario ... 1.9 muy activo).
/// 3. Se ajusta al objetivo: perder peso −20 %, masa muscular +10 %,
///    recomposición −5 %, rendimiento +5 %, resistencia sin cambio.
/// 4. Proteína 1.8 g/kg (2.0 si busca masa muscular o recomposición),
///    grasas 25 % de las calorías y el resto en carbohidratos.
MacroTotals computeNutritionGoals(OnboardingData data) {
  final PersonalInfo p = data.personalInfo;
  final double kg =
      p.weightUnit == WeightUnit.kg ? p.weight : p.weight / 2.20462;

  final double base = 10 * kg + 6.25 * p.height - 5 * p.age;
  final double bmr;
  switch (p.gender) {
    case Gender.male:
      bmr = base + 5;
    case Gender.female:
      bmr = base - 161;
    case Gender.other:
      bmr = base - 78; // promedio entre ambas fórmulas
  }

  final double activity;
  switch (data.trainingHabits.activityLevel) {
    case ActivityLevel.sedentary:
      activity = 1.2;
    case ActivityLevel.light:
      activity = 1.375;
    case ActivityLevel.moderate:
      activity = 1.55;
    case ActivityLevel.active:
      activity = 1.725;
    case ActivityLevel.veryActive:
      activity = 1.9;
  }

  final Goal? goal = data.goal;
  final double goalFactor;
  switch (goal) {
    case Goal.loseWeight:
      goalFactor = 0.80;
    case Goal.gainMuscle:
      goalFactor = 1.10;
    case Goal.bodyRecomposition:
      goalFactor = 0.95;
    case Goal.athleticPerformance:
      goalFactor = 1.05;
    case Goal.improveEndurance:
    case null:
      goalFactor = 1.0;
  }

  final double calories =
      (bmr * activity * goalFactor).clamp(1200.0, 5000.0).toDouble();

  final double proteinPerKg =
      (goal == Goal.gainMuscle || goal == Goal.bodyRecomposition) ? 2.0 : 1.8;
  final double protein = kg * proteinPerKg;
  final double fats = calories * 0.25 / 9;
  final double carbs = math.max(0, (calories - protein * 4 - fats * 9) / 4);

  return MacroTotals(
    calories: (calories / 10).round() * 10,
    protein: protein.round(),
    carbs: carbs.round(),
    fats: fats.round(),
  );
}