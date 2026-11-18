import '../../features/onboarding/models/onboarding_data.dart';

/// Perfil del usuario: datos de la cuenta + lo que capturó el onboarding.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.onboardingData,
    this.authProvider = 'local',
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final OnboardingData onboardingData;

  /// Cómo inicia sesión la persona: `local` (correo y contraseña) o `google`.
  final String authProvider;

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
      authProvider: authProvider,
    );
  }
}
