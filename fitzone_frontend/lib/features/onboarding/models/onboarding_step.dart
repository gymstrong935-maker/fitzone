import '../../plan_selection/models/plan.dart';

/// Pasos del onboarding, en el orden en que aparecen.
enum OnboardingStep {
  trainer,
  personalInfo,
  measurements,
  goals,
  experience,
  habits,
}

/// El plan gratuito no tiene paso de entrenador (igual que en el diseño).
List<OnboardingStep> stepsForPlan(PlanId plan) {
  return <OnboardingStep>[
    if (plan != PlanId.free) OnboardingStep.trainer,
    OnboardingStep.personalInfo,
    OnboardingStep.measurements,
    OnboardingStep.goals,
    OnboardingStep.experience,
    OnboardingStep.habits,
  ];
}