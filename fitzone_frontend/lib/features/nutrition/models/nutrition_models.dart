/// Totales del día: calorías y macronutrientes.
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

class Food {
  const Food({required this.name, required this.quantity, required this.unit});

  final String name;
  final int quantity;
  final String unit;
}

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.foods,
  });

  final int id;
  final String name;
  final String time;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final List<Food> foods;
}

/// Otro nutriente: con `max` muestra "valor / máximo" y una barra.
class ExtraNutrient {
  const ExtraNutrient({
    required this.name,
    required this.value,
    required this.unit,
    this.max,
  });

  final String name;
  final int value;
  final String unit;
  final int? max;
}