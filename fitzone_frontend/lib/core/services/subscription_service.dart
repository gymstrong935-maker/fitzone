import '../../features/payment_method/models/payment_models.dart';
import '../api/api_client.dart';
import 'backend_models.dart';

enum SubscriptionStatus { active, pending, rejected, expired, none }

/// Método de pago del front -> texto que espera el backend.
String payMethodToBackend(PayMethod method) {
  switch (method) {
    case PayMethod.cash:
      return 'Efectivo';
    case PayMethod.card:
      return 'Tarjeta';
    case PayMethod.digital:
      return 'Nequi';
  }
}

/// Estado "global" de un usuario a partir de todas sus suscripciones.
SubscriptionStatus resolveStatus(List<BackendSubscription> subscriptions) {
  if (subscriptions.any((BackendSubscription s) => s.isActive)) {
    return SubscriptionStatus.active;
  }

  // Los ids de Mongo crecen con el tiempo: el id mayor es la más reciente.
  final List<BackendSubscription> sorted = List<BackendSubscription>.of(
    subscriptions,
  )..sort((BackendSubscription a, BackendSubscription b) => b.id.compareTo(a.id));

  for (final BackendSubscription s in sorted) {
    switch (s.estado) {
      case 'pendiente':
        return SubscriptionStatus.pending;
      case 'rechazada':
        return SubscriptionStatus.rejected;
      case 'vencida':
      case 'activa': // activa pero con fecha vencida
        return SubscriptionStatus.expired;
      default:
        continue; // "cancelada": se ignora
    }
  }
  return SubscriptionStatus.none;
}

class SubscriptionService {
  SubscriptionService(this._api);

  final ApiClient _api;

  Future<List<BackendSubscription>> listForUser(String userId) async {
    final dynamic data = await _api.get('/api/subscriptions/usuario/$userId');
    final List<dynamic> list = data is List ? data : const <dynamic>[];
    return <BackendSubscription>[
      for (final dynamic s in list)
        BackendSubscription.fromJson(s as Map<String, dynamic>),
    ];
  }

  Future<SubscriptionStatus> statusFor(String userId) async {
    return resolveStatus(await listForUser(userId));
  }

  /// Un usuario ya registrado pide otro plan (queda pendiente de aprobación).
  Future<void> changePlan({
    required String userId,
    required String planId,
    required String metodoPago,
  }) async {
    await _api.post(
      '/api/subscriptions/cambiar-plan',
      body: <String, dynamic>{
        'usuarioId': userId,
        'nuevoPlanId': planId,
        'metodoPago': metodoPago,
      },
    );
  }
}