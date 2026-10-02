import '../../features/onboarding/models/onboarding_data.dart';

/// Perfil del usuario: datos de la cuenta + lo que capturó el onboarding.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.onboardingData,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final OnboardingData onboardingData;
}