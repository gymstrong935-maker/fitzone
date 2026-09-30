/// Nivel del entrenador (se usará en pantallas futuras).
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
  final int price;
  final String priceDescription;
  final List<String> services;
  final TrainerLevel level;
}

/// Ventaja de contar con un entrenador (tarjeta "¿Por qué necesitas un entrenador?").
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