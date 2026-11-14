/// Nivel de experiencia del usuario.
/// `apiValue` es el texto que usa el diseño (útil cuando conectemos el backend).
enum ExperienceLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const ExperienceLevel(this.apiValue);

  final String apiValue;
}

/// Datos de presentación de un nivel (tarjeta).
class ExperienceOption {
  const ExperienceOption({
    required this.id,
    required this.title,
    required this.description,
    required this.reps,
    required this.icon,
  });

  final ExperienceLevel id;
  final String title;
  final String description;

  /// Texto de la pastilla, p. ej. "8 reps".
  final String reps;

  /// Emoji que se muestra en el recuadro.
  final String icon;
}