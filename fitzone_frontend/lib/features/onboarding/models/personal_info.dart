import 'dart:math' as math;

enum Gender { male, female, other }

enum WeightUnit { kg, lb }

/// Condición psicológica (cada valor va de 0 a 10).
class PsychologicalCondition {
  const PsychologicalCondition({
    this.motivation = 7,
    this.stress = 5,
    this.energy = 6,
  });

  final int motivation;
  final int stress;
  final int energy;

  PsychologicalCondition copyWith({
    int? motivation,
    int? stress,
    int? energy,
  }) {
    return PsychologicalCondition(
      motivation: motivation ?? this.motivation,
      stress: stress ?? this.stress,
      energy: energy ?? this.energy,
    );
  }
}

class MedicalConditions {
  const MedicalConditions({this.physical = '', this.psychological = ''});

  final String physical;
  final String psychological;

  MedicalConditions copyWith({String? physical, String? psychological}) {
    return MedicalConditions(
      physical: physical ?? this.physical,
      psychological: psychological ?? this.psychological,
    );
  }
}

/// Datos del paso "Información Personal" (con los mismos valores por defecto
/// que el diseño).
class PersonalInfo {
  const PersonalInfo({
    this.age = 0,
    this.weight = 0,
    this.weightUnit = WeightUnit.kg,
    this.height = 0,
    this.gender = Gender.male,
    this.physicalCondition = 5,
    this.psychologicalCondition = const PsychologicalCondition(),
    this.medicalConditions = const MedicalConditions(),
    this.touched = const <String>{},
  });

  /// Claves de los controles que traen un valor de partida y que la persona
  /// debe confirmar tocándolos: género y los cuatro deslizadores.
  static const String kGender = 'gender';
  static const String kPhysical = 'physical';
  static const String kMotivation = 'motivation';
  static const String kStress = 'stress';
  static const String kEnergy = 'energy';
  static const Set<String> allTouched = <String>{
    kGender, kPhysical, kMotivation, kStress, kEnergy,
  };

  /// Controles que la persona ya llenó / confirmó.
  final Set<String> touched;

  final int age;
  final double weight;
  final WeightUnit weightUnit;

  /// Estatura en cm.
  final int height;
  final Gender gender;

  /// 0 a 10.
  final int physicalCondition;
  final PsychologicalCondition psychologicalCondition;
  final MedicalConditions medicalConditions;

  PersonalInfo copyWith({
    int? age,
    double? weight,
    WeightUnit? weightUnit,
    int? height,
    Gender? gender,
    int? physicalCondition,
    PsychologicalCondition? psychologicalCondition,
    MedicalConditions? medicalConditions,
    Set<String>? touched,
  }) {
    return PersonalInfo(
      age: age ?? this.age,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      physicalCondition: physicalCondition ?? this.physicalCondition,
      psychologicalCondition:
          psychologicalCondition ?? this.psychologicalCondition,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      touched: touched ?? this.touched,
    );
  }

  PersonalInfo withTouched(String key) =>
      copyWith(touched: <String>{...touched, key});

  double get weightKg => weightUnit == WeightUnit.kg ? weight : weight / 2.20462;

  /// Datos obligatorios que todavía faltan (en el orden de la pantalla).
  List<String> get missing => <String>[
        if (age < 10) 'edad',
        if (!touched.contains(kGender)) 'género',
        if (weightKg < 20) 'peso',
        if (height < 100) 'estatura',
        if (!touched.contains(kPhysical)) 'condición física',
        if (!touched.contains(kMotivation)) 'motivación',
        if (!touched.contains(kStress)) 'nivel de estrés',
        if (!touched.contains(kEnergy)) 'energía',
        if (medicalConditions.physical.trim().isEmpty) 'condiciones médicas',
      ];

  bool get isComplete => missing.isEmpty;

  /// Aplica los mínimos del diseño (edad 10, peso 20, estatura 100).
  PersonalInfo sanitized() {
    return copyWith(
      age: math.max(age, 10),
      weight: math.max(weight, 20.0),
      height: math.max(height, 100),
    );
  }
}