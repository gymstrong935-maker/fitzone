import 'body_measurements.dart';
import 'personal_info.dart';
import 'trainer.dart';

/// Datos que va acumulando el onboarding.
/// Iremos agregando campos con cada paso nuevo.
class OnboardingData {
  const OnboardingData({
    this.trainer,
    this.personalInfo = const PersonalInfo(),
    this.bodyMeasurements = const BodyMeasurements(),
  });

  final Trainer? trainer;
  final PersonalInfo personalInfo;
  final BodyMeasurements bodyMeasurements;

  OnboardingData copyWith({
    Trainer? trainer,
    PersonalInfo? personalInfo,
    BodyMeasurements? bodyMeasurements,
  }) {
    return OnboardingData(
      trainer: trainer ?? this.trainer,
      personalInfo: personalInfo ?? this.personalInfo,
      bodyMeasurements: bodyMeasurements ?? this.bodyMeasurements,
    );
  }
}