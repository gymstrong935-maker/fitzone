import '../../features/onboarding/data/trainers_data.dart';
import '../../features/onboarding/models/body_measurements.dart';
import '../../features/onboarding/models/experience_level.dart';
import '../../features/onboarding/models/goal.dart';
import '../../features/onboarding/models/onboarding_data.dart';
import '../../features/onboarding/models/personal_info.dart';
import '../../features/onboarding/models/trainer.dart';
import '../../features/onboarding/models/training_habits.dart';

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final T value in values) {
    if (value.name == name) return value;
  }
  return null;
}

int _int(Object? v, int fallback) => v is num ? v.toInt() : fallback;

double _double(Object? v, double fallback) => v is num ? v.toDouble() : fallback;

String _string(Object? v) => v is String ? v : '';

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const <String, dynamic>{};

Map<String, dynamic> onboardingToJson(OnboardingData d) {
  final PersonalInfo p = d.personalInfo;
  final TrainingHabits h = d.trainingHabits;

  return <String, dynamic>{
    'trainerId': d.trainer?.id,
    'personalInfo': <String, dynamic>{
      'age': p.age,
      'weight': p.weight,
      'weightUnit': p.weightUnit.name,
      'height': p.height,
      'gender': p.gender.name,
      'physicalCondition': p.physicalCondition,
      'motivation': p.psychologicalCondition.motivation,
      'stress': p.psychologicalCondition.stress,
      'energy': p.psychologicalCondition.energy,
      'medicalPhysical': p.medicalConditions.physical,
      'medicalPsychological': p.medicalConditions.psychological,
    },
    'measurements': <String, dynamic>{
      'skinfolds': <String, dynamic>{
        for (final MapEntry<SkinfoldSite, double> e
            in d.bodyMeasurements.skinfolds.entries)
          e.key.name: e.value,
      },
      'circumferences': <String, dynamic>{
        for (final MapEntry<CircumferenceSite, double> e
            in d.bodyMeasurements.circumferences.entries)
          e.key.name: e.value,
      },
    },
    'goal': d.goal?.name,
    'experienceLevel': d.experienceLevel?.name,
    'habits': <String, dynamic>{
      'frequency': h.frequency,
      'duration': h.duration,
      'sleepQuality': h.sleepQuality.name,
      'sleepDuration': h.sleepDuration,
      'activityLevel': h.activityLevel.name,
      'availability': h.availability,
    },
  };
}

OnboardingData onboardingFromJson(Map<String, dynamic> json) {
  final Map<String, dynamic> p = _map(json['personalInfo']);
  final Map<String, dynamic> m = _map(json['measurements']);
  final Map<String, dynamic> h = _map(json['habits']);

  Trainer? trainer;
  final Object? trainerId = json['trainerId'];
  if (trainerId is String) {
    for (final Trainer t in kTrainers) {
      if (t.id == trainerId) trainer = t;
    }
  }

  final Map<SkinfoldSite, double> skinfolds = <SkinfoldSite, double>{};
  _map(m['skinfolds']).forEach((String key, Object? value) {
    final SkinfoldSite? site = _enumByName(SkinfoldSite.values, key);
    if (site != null && value is num) skinfolds[site] = value.toDouble();
  });

  final Map<CircumferenceSite, double> circumferences =
      <CircumferenceSite, double>{};
  _map(m['circumferences']).forEach((String key, Object? value) {
    final CircumferenceSite? site = _enumByName(CircumferenceSite.values, key);
    if (site != null && value is num) circumferences[site] = value.toDouble();
  });

  final Object? availability = h['availability'];

  return OnboardingData(
    trainer: trainer,
    personalInfo: PersonalInfo(
      age: _int(p['age'], 25),
      weight: _double(p['weight'], 70),
      weightUnit: _enumByName(WeightUnit.values, p['weightUnit']) ?? WeightUnit.kg,
      height: _int(p['height'], 170),
      gender: _enumByName(Gender.values, p['gender']) ?? Gender.male,
      physicalCondition: _int(p['physicalCondition'], 5),
      psychologicalCondition: PsychologicalCondition(
        motivation: _int(p['motivation'], 7),
        stress: _int(p['stress'], 5),
        energy: _int(p['energy'], 6),
      ),
      medicalConditions: MedicalConditions(
        physical: _string(p['medicalPhysical']),
        psychological: _string(p['medicalPsychological']),
      ),
    ),
    bodyMeasurements: BodyMeasurements(
      skinfolds: skinfolds,
      circumferences: circumferences,
    ),
    goal: _enumByName(Goal.values, json['goal']),
    experienceLevel: _enumByName(ExperienceLevel.values, json['experienceLevel']),
    trainingHabits: TrainingHabits(
      frequency: _int(h['frequency'], 3),
      duration: _int(h['duration'], 60),
      sleepQuality:
          _enumByName(SleepQuality.values, h['sleepQuality']) ?? SleepQuality.good,
      sleepDuration: _double(h['sleepDuration'], 7),
      activityLevel: _enumByName(ActivityLevel.values, h['activityLevel']) ??
          ActivityLevel.moderate,
      availability: availability is List
          ? <String>[for (final Object? a in availability) a.toString()]
          : const <String>[],
    ),
  );
}