import 'body_measurements.dart';
import 'experience_level.dart';
import 'goal.dart';
import 'personal_info.dart';
import 'trainer.dart';
import 'training_habits.dart';

/// Datos que acumula el onboarding (un campo por paso).
class OnboardingData {
  const OnboardingData({
    this.trainer,
    this.personalInfo = const PersonalInfo(),
    this.bodyMeasurements = const BodyMeasurements(),
    this.goal,
    this.experienceLevel,
    this.trainingHabits = const TrainingHabits(),
  });

  final Trainer? trainer;
  final PersonalInfo personalInfo;
  final BodyMeasurements bodyMeasurements;
  final Goal? goal;
  final ExperienceLevel? experienceLevel;
  final TrainingHabits trainingHabits;

  OnboardingData copyWith({
    Trainer? trainer,
    PersonalInfo? personalInfo,
    BodyMeasurements? bodyMeasurements,
    Goal? goal,
    ExperienceLevel? experienceLevel,
    TrainingHabits? trainingHabits,
  }) {
    return OnboardingData(
      trainer: trainer ?? this.trainer,
      personalInfo: personalInfo ?? this.personalInfo,
      bodyMeasurements: bodyMeasurements ?? this.bodyMeasurements,
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      trainingHabits: trainingHabits ?? this.trainingHabits,
    );
  }
}