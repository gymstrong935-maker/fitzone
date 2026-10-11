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

  /// Lunes a domingo de la semana actual: `true` = hubo entrenamiento ese día.
  List<bool> get weekProgress {
    final DateTime now = DateTime.now();
    final DateTime monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final DateTime base = DateTime.utc(monday.year, monday.month, monday.day);

    final List<bool> result = List<bool>.filled(7, false);
    for (final SavedWorkout w in sessions) {
      final DateTime d = w.date.toLocal();
      final int diff = DateTime.utc(d.year, d.month, d.day).difference(base).inDays;
      if (diff >= 0 && diff < 7) result[diff] = true;
    }
    return result;
  }

  /// Cuántos entrenamientos se hicieron esta semana.
  int get sessionsThisWeek {
    final DateTime now = DateTime.now();
    final DateTime monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final DateTime base = DateTime.utc(monday.year, monday.month, monday.day);

    int count = 0;
    for (final SavedWorkout w in sessions) {
      final DateTime d = w.date.toLocal();
      final int diff = DateTime.utc(d.year, d.month, d.day).difference(base).inDays;
      if (diff >= 0 && diff < 7) count++;
    }
    return count;
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