import 'dart:math' as math;

import '../../features/onboarding/models/body_measurements.dart';
import '../../features/onboarding/models/experience_level.dart';
import '../../features/onboarding/models/goal.dart';
import '../../features/onboarding/models/onboarding_data.dart';
import '../../features/onboarding/models/personal_info.dart';
import '../../features/onboarding/models/training_habits.dart';

const double _lbPerKg = 2.20462;

/// Duración del período de entrenamiento (igual que el mesociclo de "Mi Plan").
const int kTrainingPeriodWeeks = 4;

double _round(double value, int decimals) {
  final num factor = math.pow(10, decimals);
  return (value * factor).round() / factor;
}

double? _num(Object? value) => value is num ? value.toDouble() : null;

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

// ═══════════════════════════════════════════════════════════════════════════
// Tablas de equivalencias
// ═══════════════════════════════════════════════════════════════════════════

const Map<CircumferenceSite, String> _circumferenceKeys =
    <CircumferenceSite, String>{
  CircumferenceSite.arm: 'brazo',
  CircumferenceSite.chest: 'pecho',
  CircumferenceSite.waist: 'cintura',
  CircumferenceSite.hip: 'cadera',
  CircumferenceSite.thigh: 'muslo',
  CircumferenceSite.calf: 'pantorrilla',
};

const Map<SkinfoldSite, String> _skinfoldKeys = <SkinfoldSite, String>{
  SkinfoldSite.triceps: 'triceps',
  SkinfoldSite.subscapular: 'subescapular',
  SkinfoldSite.chest: 'pecho',
  SkinfoldSite.abdominal: 'abdominal',
  SkinfoldSite.thigh: 'muslo',
  SkinfoldSite.suprailiac: 'suprailiaco',
  SkinfoldSite.midaxillary: 'axilarMedio',
};

String? _levelToBackend(ExperienceLevel? level) {
  switch (level) {
    case ExperienceLevel.beginner:
      return 'principiante';
    case ExperienceLevel.intermediate:
      return 'intermedio';
    case ExperienceLevel.advanced:
      return 'avanzado';
    case null:
      return null;
  }
}

ExperienceLevel? _levelFromBackend(Object? value) {
  switch (value) {
    case 'principiante':
      return ExperienceLevel.beginner;
    case 'intermedio':
      return ExperienceLevel.intermediate;
    case 'avanzado':
      return ExperienceLevel.advanced;
    default:
      return null;
  }
}

String _genderToBackend(Gender gender) {
  switch (gender) {
    case Gender.male:
      return 'masculino';
    case Gender.female:
      return 'femenino';
    case Gender.other:
      return 'otro';
  }
}

Gender _genderFromBackend(Object? value) {
  switch (value) {
    case 'femenino':
      return Gender.female;
    case 'otro':
      return Gender.other;
    default:
      return Gender.male;
  }
}

/// Calidad del sueño (4 niveles) -> escala 1 a 5 del backend.
int _sleepQualityToBackend(SleepQuality quality) {
  switch (quality) {
    case SleepQuality.poor:
      return 1;
    case SleepQuality.fair:
      return 2;
    case SleepQuality.good:
      return 4;
    case SleepQuality.excellent:
      return 5;
  }
}

SleepQuality _sleepQualityFromBackend(Object? value) {
  final int score = value is num ? value.round() : 4;
  if (score <= 1) return SleepQuality.poor;
  if (score <= 3) return SleepQuality.fair;
  if (score == 4) return SleepQuality.good;
  return SleepQuality.excellent;
}

// ═══════════════════════════════════════════════════════════════════════════
// Frontend -> Backend (payloads)
// ═══════════════════════════════════════════════════════════════════════════

/// PUT /api/users/:id
Map<String, dynamic> userProfilePayload(OnboardingData d) {
  return <String, dynamic>{
    'edad': d.personalInfo.age,
    'genero': _genderToBackend(d.personalInfo.gender),
  };
}

/// POST /api/physical-conditions
Map<String, dynamic> conditionPayload(String userId, OnboardingData d) {
  final PersonalInfo p = d.personalInfo;
  final String physical = p.medicalConditions.physical.trim();
  final String psychological = p.medicalConditions.psychological.trim();

  final String notes = <String>[
    if (physical.isNotEmpty) physical,
    if (psychological.isNotEmpty) 'Psicológicas: $psychological',
  ].join('\n');

  final String? nivel = _levelToBackend(d.experienceLevel);

  return <String, dynamic>{
    'usuarioId': userId,
    if (nivel != null) 'nivel': nivel,
    'observacionesMedicas': notes,
    'valoraciones': <String, dynamic>{
      'condicionFisica': p.physicalCondition,
      'motivacion': p.psychologicalCondition.motivation,
      'estres': p.psychologicalCondition.stress,
      'energia': p.psychologicalCondition.energy,
    },
  };
}

/// POST /api/physical-measurements
Map<String, dynamic> measurementPayload(String userId, OnboardingData d) {
  final PersonalInfo p = d.personalInfo;

  final double kg =
      p.weightUnit == WeightUnit.kg ? p.weight : p.weight / _lbPerKg;
  final double peso = math.min(_round(kg, 1), 500);
  final double altura = math.min(_round(p.height / 100, 2), 3);
  final double imc = altura > 0 ? _round(peso / (altura * altura), 1) : 0;

  final Map<String, double> medidas = <String, double>{};
  d.bodyMeasurements.circumferences.forEach((CircumferenceSite site, double v) {
    final String? key = _circumferenceKeys[site];
    if (key != null && v > 0) medidas[key] = math.min(v, 400);
  });

  final Map<String, double> pliegues = <String, double>{};
  d.bodyMeasurements.skinfolds.forEach((SkinfoldSite site, double v) {
    final String? key = _skinfoldKeys[site];
    if (key != null && v > 0) pliegues[key] = math.min(v, 100);
  });

  return <String, dynamic>{
    'usuarioId': userId,
    'peso': peso,
    'altura': altura,
    if (imc > 0) 'imc': imc,
    'unidadPeso': p.weightUnit == WeightUnit.kg ? 'kg' : 'lb',
    if (medidas.isNotEmpty) 'medidas': medidas,
    if (pliegues.isNotEmpty) 'pliegues': pliegues,
  };
}

/// POST /api/sleep-quality
Map<String, dynamic> sleepPayload(String userId, OnboardingData d) {
  final TrainingHabits h = d.trainingHabits;
  return <String, dynamic>{
    'usuarioId': userId,
    'horasDormidas': h.sleepDuration,
    'calidadPercibida': _sleepQualityToBackend(h.sleepQuality),
  };
}

/// POST /api/motivation (0-10 -> 1-5; estrés y energía van en el comentario)
Map<String, dynamic> motivationPayload(String userId, OnboardingData d) {
  final PsychologicalCondition psy = d.personalInfo.psychologicalCondition;
  final int level = (psy.motivation / 2).round().clamp(1, 5);

  return <String, dynamic>{
    'usuarioId': userId,
    'nivelMotivacion': level,
    'comentario': 'Motivación ${psy.motivation}/10 · '
        'Estrés ${psy.stress}/10 · '
        'Energía ${psy.energy}/10 · '
        'Condición física ${d.personalInfo.physicalCondition}/10',
  };
}

/// POST /api/training-frequency
Map<String, dynamic> frequencyPayload(String userId, OnboardingData d) {
  final TrainingHabits h = d.trainingHabits;
  return <String, dynamic>{
    'usuarioId': userId,
    'diasPorSemana': h.frequency,
    'duracionSesionMinutos': h.duration,
    'nivelActividad': h.activityLevel.apiValue,
    if (h.availability.isNotEmpty) 'diasPreferidos': h.availability,
  };
}

/// POST /api/training-periods (el objetivo es un período de entrenamiento)
Map<String, dynamic> periodPayload(String userId, Goal goal) {
  final DateTime start = DateTime.now();
  final DateTime end = start.add(const Duration(days: 7 * kTrainingPeriodWeeks));

  return <String, dynamic>{
    'usuarioId': userId,
    'objetivo': goal.apiValue,
    'duracionSemanas': kTrainingPeriodWeeks,
    'fechaInicio': start.toUtc().toIso8601String(),
    'fechaFin': end.toUtc().toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Backend -> Frontend (restaurar el onboarding)
// ═══════════════════════════════════════════════════════════════════════════

/// Reconstruye el onboarding a partir de lo guardado en el servidor.
/// Devuelve `null` si el usuario todavía no tiene condición física guardada
/// (o sea, no terminó el onboarding).
OnboardingData? onboardingFromRemote({
  required Map<String, dynamic> user,
  Map<String, dynamic>? condition,
  Map<String, dynamic>? measurement,
  Map<String, dynamic>? sleep,
  Map<String, dynamic>? frequency,
  Map<String, dynamic>? period,
}) {
  if (condition == null) return null;

  // ── Valoraciones 0-10 ──
  final Map<String, dynamic>? ratings = _asMap(condition['valoraciones']);
  int slider(String key, int fallback) =>
      _num(ratings?[key])?.round().clamp(0, 10) ?? fallback;

  // ── Peso y estatura ──
  final double? kg = _num(measurement?['peso']);
  final bool usesPounds = measurement?['unidadPeso'] == 'lb';
  double weight = 70;
  WeightUnit unit = WeightUnit.kg;
  if (kg != null) {
    if (usesPounds) {
      weight = _round(kg * _lbPerKg, 1);
      unit = WeightUnit.lb;
    } else {
      weight = _round(kg, 1);
    }
  }
  final double? meters = _num(measurement?['altura']);
  final int height = meters == null ? 170 : (meters * 100).round();

  // ── Circunferencias y pliegues ──
  final Map<CircumferenceSite, double> circumferences =
      <CircumferenceSite, double>{};
  final Map<String, dynamic>? medidas = _asMap(measurement?['medidas']);
  _circumferenceKeys.forEach((CircumferenceSite site, String key) {
    final double? v = _num(medidas?[key]);
    if (v != null && v > 0) circumferences[site] = v;
  });

  final Map<SkinfoldSite, double> skinfolds = <SkinfoldSite, double>{};
  final Map<String, dynamic>? pliegues = _asMap(measurement?['pliegues']);
  _skinfoldKeys.forEach((SkinfoldSite site, String key) {
    final double? v = _num(pliegues?[key]);
    if (v != null && v > 0) skinfolds[site] = v;
  });

  // ── Objetivo ──
  Goal? goal;
  final Object? objective = period?['objetivo'];
  for (final Goal g in Goal.values) {
    if (g.apiValue == objective) goal = g;
  }

  // ── Hábitos ──
  ActivityLevel activity = ActivityLevel.moderate;
  for (final ActivityLevel a in ActivityLevel.values) {
    if (a.apiValue == frequency?['nivelActividad']) activity = a;
  }

  final int days = _num(frequency?['diasPorSemana'])?.round().clamp(1, 7) ?? 3;
  final int duration =
      _num(frequency?['duracionSesionMinutos'])?.round().clamp(30, 120) ?? 60;

  return OnboardingData(
    personalInfo: PersonalInfo(
      age: _num(user['edad'])?.round().clamp(10, 120) ?? 25,
      weight: weight,
      weightUnit: unit,
      height: height,
      gender: _genderFromBackend(user['genero']),
      physicalCondition: slider('condicionFisica', 5),
      psychologicalCondition: PsychologicalCondition(
        motivation: slider('motivacion', 7),
        stress: slider('estres', 5),
        energy: slider('energia', 6),
      ),
      medicalConditions: MedicalConditions(
        physical: (condition['observacionesMedicas'] ?? '').toString(),
      ),
    ),
    bodyMeasurements: BodyMeasurements(
      skinfolds: skinfolds,
      circumferences: circumferences,
    ),
    goal: goal,
    experienceLevel: _levelFromBackend(condition['nivel']),
    trainingHabits: TrainingHabits(
      frequency: days,
      duration: duration,
      sleepQuality: _sleepQualityFromBackend(sleep?['calidadPercibida']),
      sleepDuration:
          (_num(sleep?['horasDormidas']) ?? 7).clamp(4.0, 12.0).toDouble(),
      activityLevel: activity,
    ),
  );
}