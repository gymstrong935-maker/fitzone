import '../../features/onboarding/models/goal.dart';
import '../../features/onboarding/models/onboarding_data.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../session/session_storage.dart';
import 'onboarding_mapper.dart';

class SyncResult {
  const SyncResult({
    required this.completed,
    required this.failures,
    required this.needsActiveSubscription,
  });

  /// Pasos ya guardados en el servidor.
  final Set<String> completed;

  /// Paso -> mensaje de error (por ejemplo, sin conexión).
  final Map<String, String> failures;

  /// `true` si el servidor rechazó el envío por no tener plan activo todavía.
  final bool needsActiveSubscription;

  bool get isComplete =>
      completed.length >= OnboardingSyncService.steps.length;
}

class OnboardingSyncService {
  OnboardingSyncService(this._api, this._storage);

  final ApiClient _api;
  final SessionStorage _storage;

  /// Orden en que se envían las partes del onboarding.
  static const List<String> steps = <String>[
    'profile',
    'condition',
    'measurement',
    'sleep',
    'motivation',
    'frequency',
    'period',
  ];

  // ── Enviar ────────────────────────────────────────────────────────────────

  /// Envía solo los pasos que todavía no están en el servidor.
  Future<SyncResult> syncPending(String userId, OnboardingData data) async {
    final Set<String> done = await _storage.readSyncedSteps(userId);
    final Map<String, String> failures = <String, String>{};
    bool blocked = false;

    for (final String step in steps) {
      if (done.contains(step)) continue;

      try {
        final bool sent = await _run(step, userId, data);
        if (sent) {
          done.add(step);
          await _storage.saveSyncedSteps(userId, done);
        } else {
          // Paso que no aplica (p. ej. sin objetivo): se da por resuelto.
          done.add(step);
        }
      } on ApiException catch (e) {
        if (_isSubscriptionBlock(e)) {
          blocked = true;
          break;
        }
        failures[step] = e.message;
        if (e.isNetwork) break; // sin conexión: no insistir con el resto
      }
    }

    return SyncResult(
      completed: done,
      failures: failures,
      needsActiveSubscription: blocked,
    );
  }

  /// Registra un cambio de objetivo como un nuevo período de entrenamiento.
  Future<void> syncGoal(String userId, Goal goal) async {
    await _api.post('/api/training-periods', body: periodPayload(userId, goal));
  }

  bool _isSubscriptionBlock(ApiException e) {
    return e.statusCode == 403 && e.message.toLowerCase().contains('suscripci');
  }

  /// Ejecuta un paso. Devuelve `false` si no había nada que enviar.
  Future<bool> _run(String step, String userId, OnboardingData data) async {
    switch (step) {
      case 'profile':
        await _api.put('/api/users/$userId', body: userProfilePayload(data));
      case 'condition':
        await _api.post(
          '/api/physical-conditions',
          body: conditionPayload(userId, data),
        );
      case 'measurement':
        await _api.post(
          '/api/physical-measurements',
          body: measurementPayload(userId, data),
        );
      case 'sleep':
        await _api.post('/api/sleep-quality', body: sleepPayload(userId, data));
      case 'motivation':
        await _api.post('/api/motivation', body: motivationPayload(userId, data));
      case 'frequency':
        await _api.post(
          '/api/training-frequency',
          body: frequencyPayload(userId, data),
        );
      case 'period':
        final Goal? goal = data.goal;
        if (goal == null) return false;
        await _api.post('/api/training-periods', body: periodPayload(userId, goal));
    }
    return true;
  }

  // ── Restaurar ─────────────────────────────────────────────────────────────

  /// Reconstruye el onboarding desde el servidor (inicio de sesión en otro
  /// dispositivo). Devuelve `null` si el usuario no lo había terminado.
  Future<OnboardingData?> restore(
    String userId,
    Map<String, dynamic> userJson,
  ) async {
    final List<Map<String, dynamic>?> r =
        await Future.wait(<Future<Map<String, dynamic>?>>[
      _latest('/api/physical-conditions/usuario/$userId'),
      _latest('/api/physical-measurements/usuario/$userId'),
      _latest('/api/sleep-quality/usuario/$userId'),
      _latest('/api/training-frequency/usuario/$userId'),
      _latest('/api/training-periods/usuario/$userId'),
    ]);

    final OnboardingData? data = onboardingFromRemote(
      user: userJson,
      condition: r[0],
      measurement: r[1],
      sleep: r[2],
      frequency: r[3],
      period: r[4],
    );

    // Lo que se acaba de leer del servidor ya está sincronizado.
    if (data != null) {
      await _storage.saveSyncedSteps(userId, steps.toSet());
    }
    return data;
  }

  /// El registro más reciente de una lista (el `_id` mayor).
  Future<Map<String, dynamic>?> _latest(String path) async {
    final dynamic data = await _api.get(path);
    if (data is! List || data.isEmpty) return null;

    Map<String, dynamic>? best;
    for (final dynamic item in data) {
      if (item is! Map<String, dynamic>) continue;
      if (best == null ||
          (item['_id'] ?? '').toString().compareTo((best['_id'] ?? '').toString()) >
              0) {
        best = item;
      }
    }
    return best;
  }
}