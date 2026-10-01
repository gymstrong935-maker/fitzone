import 'personal_info.dart';
import 'trainer.dart';

/// Datos que va acumulando el onboarding.
/// Iremos agregando campos con cada paso nuevo.
class OnboardingData {
  const OnboardingData({
    this.trainer,
    this.personalInfo = const PersonalInfo(),
  });

  final Trainer? trainer;
  final PersonalInfo personalInfo;

  OnboardingData copyWith({Trainer? trainer, PersonalInfo? personalInfo}) {
    return OnboardingData(
      trainer: trainer ?? this.trainer,
      personalInfo: personalInfo ?? this.personalInfo,
    );
  }
}