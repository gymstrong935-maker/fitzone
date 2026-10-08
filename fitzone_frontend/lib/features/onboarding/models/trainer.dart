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

  /// Precio mensual en USD.
  final int price;
  final String priceDescription;
  final List<String> services;
  final TrainerLevel level;

  Trainer copyWith({
    String? id, String? name, String? photo, String? specialty, int? experience,
    List<String>? certifications, double? rating, String? description,
    String? trainingType, int? price, String? priceDescription,
    List<String>? services, TrainerLevel? level,
  }) {
    return Trainer(
      id: id ?? this.id, name: name ?? this.name, photo: photo ?? this.photo,
      specialty: specialty ?? this.specialty, experience: experience ?? this.experience,
      certifications: certifications ?? this.certifications, rating: rating ?? this.rating,
      description: description ?? this.description, trainingType: trainingType ?? this.trainingType,
      price: price ?? this.price, priceDescription: priceDescription ?? this.priceDescription,
      services: services ?? this.services, level: level ?? this.level,
    );
  }
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