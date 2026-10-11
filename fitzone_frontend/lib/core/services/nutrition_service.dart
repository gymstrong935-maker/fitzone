import '../../features/nutrition/models/nutrition_models.dart';
import '../api/api_client.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// "Avena (80 g)" -> Food(name: "Avena", amount: "80 g")
Food parseFood(String raw) {
  final RegExpMatch? m = RegExp(r'^(.*?)\s*\(([^)]*)\)\s*$').firstMatch(raw.trim());
  if (m == null) return Food(name: raw.trim());
  return Food(name: m.group(1)!.trim(), amount: m.group(2)!.trim());
}

String foodToText(Food food) {
  final String amount = food.amount.trim();
  return amount.isEmpty ? food.name.trim() : '${food.name.trim()} ($amount)';
}

/// Un registro del servidor puede traer varias comidas.
List<Meal> mealsFromDoc(Map<String, dynamic> doc) {
  final String docId = (doc['_id'] ?? doc['id'] ?? '').toString();
  final DateTime loggedAt =
      DateTime.tryParse((doc['fecha'] ?? '').toString())?.toLocal() ??
          DateTime.now();
  final Object? rawMeals = doc['comidas'];
  if (rawMeals is! List) return const <Meal>[];

  final List<Meal> meals = <Meal>[];
  for (int i = 0; i < rawMeals.length; i++) {
    final Object? c = rawMeals[i];
    if (c is! Map<String, dynamic>) continue;

    final String hora = (c['hora'] ?? '').toString();
    final Object? rawFoods = c['alimentos'];

    meals.add(
      Meal(
        id: '$docId#$i',
        docId: docId,
        type: MealType.fromApi(c['tipo']),
        time: hora.isEmpty ? '${_two(loggedAt.hour)}:${_two(loggedAt.minute)}' : hora,
        loggedAt: loggedAt,
        calories: (c['calorias'] as num?)?.round() ?? 0,
        protein: (c['proteina'] as num?)?.round() ?? 0,
        carbs: (c['carbohidratos'] as num?)?.round() ?? 0,
        fats: (c['grasas'] as num?)?.round() ?? 0,
        foods: rawFoods is List
            ? <Food>[for (final Object? f in rawFoods) parseFood(f.toString())]
            : const <Food>[],
      ),
    );
  }
  return meals;
}

class NutritionService {
  NutritionService(this._api);

  final ApiClient _api;

  Future<List<Meal>> list(String userId) async {
    final dynamic data = await _api.get('/api/dietary-control/usuario/$userId');
    final List<dynamic> docs = data is List ? data : const <dynamic>[];

    return <Meal>[
      for (final dynamic doc in docs)
        if (doc is Map<String, dynamic>) ...mealsFromDoc(doc),
    ];
  }

  Future<Meal> create(String userId, NewMeal meal) async {
    final dynamic data = await _api.post(
      '/api/dietary-control',
      body: <String, dynamic>{
        'usuarioId': userId,
        'fecha': DateTime.now().toUtc().toIso8601String(),
        'comidas': <Map<String, dynamic>>[
          <String, dynamic>{
            'tipo': meal.type.apiValue,
            'hora': meal.time,
            'alimentos': <String>[for (final Food f in meal.foods) foodToText(f)],
            'calorias': meal.calories,
            'proteina': meal.protein,
            'carbohidratos': meal.carbs,
            'grasas': meal.fats,
          },
        ],
      },
    );
    return mealsFromDoc(data as Map<String, dynamic>).first;
  }

  Future<void> delete(String docId) async {
    await _api.delete('/api/dietary-control/$docId');
  }
}