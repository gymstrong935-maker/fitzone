import 'trainer.dart';

/// Datos que va acumulando el onboarding.
/// Por ahora solo guarda el entrenador; iremos agregando campos por paso.
class OnboardingData {
  const OnboardingData({this.trainer});

  final Trainer? trainer;

  OnboardingData copyWith({Trainer? trainer}) {
    return OnboardingData(trainer: trainer ?? this.trainer);
  }
}