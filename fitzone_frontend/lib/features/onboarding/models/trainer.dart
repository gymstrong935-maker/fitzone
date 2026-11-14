enum TrainerLevel { standard, premium, elite }

class Trainer {
  const Trainer({
    required this.id,
    required this.name,
    required this.photo,
    required this.specialty,
    required this.experience,
    required this.certifications,
    required this.rating,
    required this.description,
    required this.trainingType,
    required this.price,
    required this.priceDescription,
    required this.services,
    required this.level,
    this.availability = const <String>[],
  });

  final String id;
  final String name;
  final String photo;
  final String specialty;

  /// Años de experiencia.
  final int experience;
  final List<String> certifications;
  final double rating;
  final String description;
  final String trainingType;

  /// Precio mensual (pesos colombianos si viene del servidor).
  final int price;
  final String priceDescription;
  final List<String> services;
  final TrainerLevel level;

  /// Horarios de atención, p. ej. "lunes 06:00-12:00".
  final List<String> availability;
}

/// Beneficio que se muestra en el panel "¿Por qué necesitas un entrenador?".
class TrainerBenefit {
  const TrainerBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;
}