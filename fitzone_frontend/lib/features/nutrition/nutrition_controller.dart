import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/nutrition_service.dart';
import 'models/nutrition_models.dart';

class NutritionController extends ChangeNotifier {
  NutritionController({
    required NutritionService service,
    required this.userId,
  }) : _service = service;

  final NutritionService _service;
  final String userId;

  List<Meal> _meals = const <Meal>[];
  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;
  String? _error;

  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  /// Comidas de hoy, ordenadas por hora.
  List<Meal> get todayMeals {
    final DateTime now = DateTime.now();
    final List<Meal> today = _meals.where((Meal m) {
      return m.loggedAt.year == now.year &&
          m.loggedAt.month == now.month &&
          m.loggedAt.day == now.day;
    }).toList();

    today.sort((Meal a, Meal b) {
      final int byTime = a.time.compareTo(b.time);
      return byTime != 0 ? byTime : a.loggedAt.compareTo(b.loggedAt);
    });
    return today;
  }

  /// Lo consumido hoy.
  MacroTotals get consumed {
    int calories = 0;
    int protein = 0;
    int carbs = 0;
    int fats = 0;
    for (final Meal m in todayMeals) {
      calories += m.calories;
      protein += m.protein;
      carbs += m.carbs;
      fats += m.fats;
    }
    return MacroTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
  }

  Future<void> load({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    if (!silent) _error = null;
    _notify();

    try {
      _meals = await _service.list(userId);
      _error = null;
      _loaded = true;
    } on ApiException catch (e) {
      if (!silent) _error = e.message;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// Agrega una comida. Lanza [ApiException] si el servidor la rechaza.
  Future<void> add(NewMeal meal) async {
    final Meal created = await _service.create(userId, meal);
    _meals = <Meal>[created, ..._meals];
    _error = null;
    _notify();
  }

  /// Borra una comida (se ve al instante; si falla, se restaura).
  Future<void> remove(Meal meal) async {
    final List<Meal> previous = _meals;
    _meals = _meals.where((Meal m) => m.docId != meal.docId).toList();
    _error = null;
    _notify();

    try {
      await _service.delete(meal.docId);
    } on ApiException catch (e) {
      _meals = previous;
      _error = e.message;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}