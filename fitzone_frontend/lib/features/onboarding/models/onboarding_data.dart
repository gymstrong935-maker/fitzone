import 'body_measurements.dart';
import 'experience_level.dart';
import 'goal.dart';
import 'personal_info.dart';
import 'trainer.dart';

/// Datos que va acumulando el onboarding.
/// Iremos agregando campos con cada paso nuevo.
class OnboardingData {
  const OnboardingData({
    this.trainer,
    this.personalInfo = const PersonalInfo(),
    this.bodyMeasurements = const BodyMeasurements(),
    this.goal,
    this.experienceLevel,
  });

  final Trainer? trainer;
  final PersonalInfo personalInfo;
  final BodyMeasurements bodyMeasurements;
  final Goal? goal;
  final ExperienceLevel? experienceLevel;

  OnboardingData copyWith({
    Trainer? trainer,
    PersonalInfo? personalInfo,
    BodyMeasurements? bodyMeasurements,
    Goal? goal,
    ExperienceLevel? experienceLevel,
  }) {
    return OnboardingData(
      trainer: trainer ?? this.trainer,
      personalInfo: personalInfo ?? this.personalInfo,
      bodyMeasurements: bodyMeasurements ?? this.bodyMeasurements,
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }
}