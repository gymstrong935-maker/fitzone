import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/workouts_service.dart';
import '../../core/session/session_storage.dart';

class WorkoutsController extends ChangeNotifier {
  WorkoutsController({
    required WorkoutsService service,
    required SessionStorage storage,
    required this.userId,
  })  : _service = service,
        _storage = storage;

  final WorkoutsService _service;
  final SessionStorage _storage;
  final String userId;

  List<SavedWorkout> _server = const <SavedWorkout>[];
  List<SavedWorkout> _pending = const <SavedWorkout>[];
  bool _loading = false;
  bool _loaded = false;
  bool _flushing = false;
  bool _disposed = false;
  String? _error;
  Timer? _timer;

  /// Todos los entrenamientos (los pendientes también), del más nuevo al más viejo.
  List<SavedWorkout> get sessions {
    final List<SavedWorkout> all = <SavedWorkout>[..._pending, ..._server];
    all.sort((SavedWorkout a, SavedWorkout b) => b.date.compareTo(a.date));
    return all;
  }

  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  int get pendingCount => _pending.length;

  // ── Indicadores calculados con los entrenamientos reales ─────────────────

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Lunes (00:00) de la semana de `date`.
  static DateTime mondayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  /// Entrenamientos de la semana actual (lunes a domingo).
  List<SavedWorkout> get sessionsOfWeek => sessionsInWeekOf(DateTime.now());

  /// Entrenamientos de la semana en la que cae `date`.
  List<SavedWorkout> sessionsInWeekOf(DateTime date) {
    final DateTime monday = mondayOf(date);
    final DateTime nextMonday =
        DateTime(monday.year, monday.month, monday.day + 7);
    return <SavedWorkout>[
      for (final SavedWorkout w in sessions)
        if (!_dayOf(w.date.toLocal()).isBefore(monday) &&
            _dayOf(w.date.toLocal()).isBefore(nextMonday))
          w,
    ];
  }

  /// Entrenamientos hechos el día de `date`, del más nuevo al más viejo.
  List<SavedWorkout> sessionsOn(DateTime date) {
    final DateTime day = _dayOf(date);
    return <SavedWorkout>[
      for (final SavedWorkout w in sessions)
        if (_dayOf(w.date.toLocal()) == day) w,
    ];
  }

  /// Posición (0 = lunes) del día de `date` dentro de la semana que empieza
  /// en `monday`. Se calcula en UTC para que el cambio de hora no la desfase.
  static int _weekIndex(DateTime date, DateTime monday) {
    final DateTime d = date.toLocal();
    return DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(monday.year, monday.month, monday.day))
        .inDays;
  }

  /// Lunes a domingo de la semana actual: `true` = hubo entrenamiento ese día.
  List<bool> get weekProgress {
    final DateTime monday = mondayOf(DateTime.now());
    final List<bool> result = List<bool>.filled(7, false);
    for (final SavedWorkout w in sessionsOfWeek) {
      final int i = _weekIndex(w.date, monday);
      if (i >= 0 && i < 7) result[i] = true;
    }
    return result;
  }

  /// Cuántos entrenamientos se hicieron esta semana.
  int get sessionsThisWeek => sessionsOfWeek.length;

  /// Minutos entrenados cada día de la semana actual (lunes a domingo).
  List<int> get minutesByWeekday {
    final DateTime monday = mondayOf(DateTime.now());
    final List<int> result = List<int>.filled(7, 0);
    for (final SavedWorkout w in sessionsOfWeek) {
      final int i = _weekIndex(w.date, monday);
      if (i >= 0 && i < 7) result[i] += w.durationMinutes;
    }
    return result;
  }

  /// Calorías de la semana actual.
  int get caloriesThisWeek =>
      sessionsOfWeek.fold<int>(0, (int sum, SavedWorkout w) => sum + w.calories);

  /// Minutos totales de la semana actual.
  int get minutesThisWeek => sessionsOfWeek
      .fold<int>(0, (int sum, SavedWorkout w) => sum + w.durationMinutes);

  /// Minutos promedio por sesión.
  ///
  /// Usa las sesiones de esta semana; si todavía no hay ninguna, la última
  /// sesión registrada. `null` si nunca se ha entrenado.
  int? get averageMinutesPerSession {
    final List<SavedWorkout> week = sessionsOfWeek;
    if (week.isNotEmpty) {
      final int total =
          week.fold<int>(0, (int sum, SavedWorkout w) => sum + w.durationMinutes);
      return (total / week.length).round();
    }
    final List<SavedWorkout> all = sessions;
    return all.isEmpty ? null : all.first.durationMinutes;
  }

  /// Energía de hoy (1 a 10) según cómo terminó la última sesión de hoy.
  /// `null` si hoy todavía no se entrenó.
  int? get energyToday {
    final List<SavedWorkout> today = sessionsOn(DateTime.now());
    if (today.isEmpty) return null;
    return energyAfter(today.first);
  }

  /// Energía restante (1 a 10) después de un entrenamiento: la fatiga manda y
  /// las agujetas intensas restan un punto más.
  static int energyAfter(SavedWorkout workout) {
    int energy;
    switch (workout.fatigue) {
      case 'none':
        energy = 9;
      case 'moderate':
        energy = 7;
      case 'fatigued':
        energy = 5;
      case 'high':
        energy = 3;
      case 'veryHigh':
        energy = 2;
      default:
        energy = 6;
    }
    if (workout.soreness == 'intense') energy -= 1;
    return energy.clamp(1, 10);
  }

  /// Días seguidos entrenando. Si hoy todavía no se entrenó, la racha sigue
  /// viva mientras se haya entrenado ayer.
  int get currentStreak {
    final Set<DateTime> days = <DateTime>{
      for (final SavedWorkout w in sessions) _dayOf(w.date.toLocal()),
    };
    if (days.isEmpty) return 0;

    DateTime cursor = _dayOf(DateTime.now());
    if (!days.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  /// Carga todo y empieza a reintentar los envíos pendientes.
  Future<void> start() async {
    _pending = await _storage.readPendingWorkouts(userId);
    _notify();

    await refresh(silent: true);
    await flushPending();

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(flushPending()),
    );
  }

  Future<void> refresh({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    if (!silent) _error = null;
    _notify();

    try {
      _server = await _service.list(userId);
      _error = null;
      _loaded = true;
    } on ApiException catch (e) {
      if (!silent) _error = e.message;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// Guarda un entrenamiento terminado: se ve al instante y se envía al
  /// servidor (si falla, queda pendiente y se reintenta).
  Future<void> record(SavedWorkout workout) async {
    _pending = <SavedWorkout>[workout.copyWith(pending: true), ..._pending];
    await _storage.savePendingWorkouts(userId, _pending);
    _notify();
    await flushPending();
  }

  Future<void> flushPending() async {
    if (_flushing || _pending.isEmpty) return;
    _flushing = true;

    try {
      // _pending guarda el más nuevo primero: se envían del más viejo al más nuevo.
      for (final SavedWorkout w in List<SavedWorkout>.of(_pending.reversed)) {
        try {
          final SavedWorkout saved = await _service.create(userId, w);

          _pending = _pending
              .where((SavedWorkout p) => p.clientId != w.clientId)
              .toList();
          _server = <SavedWorkout>[
            saved,
            ..._server.where((SavedWorkout s) => s.id != saved.id),
          ];
          await _storage.savePendingWorkouts(userId, _pending);
          _notify();
        } on ApiException catch (e) {
          final int status = e.statusCode ?? 0;
          final bool retryable =
              e.isNetwork || status == 401 || status == 403 || status >= 500;
          if (retryable) break; // se vuelve a intentar más tarde

          // Error de validación: reintentar no lo arregla.
          debugPrint('Entrenamiento descartado por el servidor: ${e.message}');
          _pending = _pending
              .where((SavedWorkout p) => p.clientId != w.clientId)
              .toList();
          await _storage.savePendingWorkouts(userId, _pending);
          _notify();
        }
      }
    } finally {
      _flushing = false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}