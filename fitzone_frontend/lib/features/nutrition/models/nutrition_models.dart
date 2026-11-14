/// Calorías y macronutrientes (metas o consumo).
class MacroTotals {
  const MacroTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fats;
}

enum MealType {
  breakfast('desayuno', 'Desayuno'),
  lunch('almuerzo', 'Almuerzo'),
  snack('snack', 'Merienda'),
  dinner('cena', 'Cena');

  const MealType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MealType fromApi(Object? value) {
    for (final MealType t in MealType.values) {
      if (t.apiValue == value) return t;
    }
    return MealType.snack;
  }
}

class Food {
  const Food({required this.name, this.amount = ''});

  final String name;

  /// Cantidad libre, p. ej. "80 g" (puede ir vacía).
  final String amount;
}

class Meal {
  const Meal({
    required this.id,
    required this.docId,
    required this.type,
    required this.time,
    required this.loggedAt,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.foods,
  });

  /// Identificador único en la lista.
  final String id;

  /// Id del registro en el servidor (para borrarlo).
  final String docId;
  final MealType type;

  /// "08:00"
  final String time;
  final DateTime loggedAt;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final List<Food> foods;

  String get name => type.label;
}

/// Comida que el usuario está agregando.
class NewMeal {
  const NewMeal({
    required this.type,
    required this.time,
    required this.foods,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
  });

  final MealType type;
  final String time;
  final List<Food> foods;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
}