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

  UserProfile copyWith({
    String? name,
    String? email,
    OnboardingData? onboardingData,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
      onboardingData: onboardingData ?? this.onboardingData,
    );
  }
}