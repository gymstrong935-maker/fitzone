import '../api/api_client.dart';

enum NotificationType { payment, reminder, workout, system }

NotificationType _typeFrom(Object? value) {
  switch (value) {
    case 'pago':
      return NotificationType.payment;
    case 'recordatorio':
      return NotificationType.reminder;
    case 'entrenamiento':
      return NotificationType.workout;
    default:
      return NotificationType.system;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.read,
    required this.sentAt,
  });

  final String id;
  final NotificationType type;
  final String message;
  final bool read;
  final DateTime sentAt;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      message: message,
      read: read ?? this.read,
      sentAt: sentAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: _typeFrom(json['tipo']),
      message: (json['mensaje'] ?? '').toString(),
      read: json['leida'] == true,
      sentAt: DateTime.tryParse((json['fechaEnvio'] ?? '').toString())
              ?.toLocal() ??
          DateTime.now(),
    );
  }
}

class NotificationsService {
  NotificationsService(this._api);

  final ApiClient _api;

  /// Notificaciones del usuario, de la más nueva a la más antigua.
  Future<List<AppNotification>> list(String userId) async {
    final dynamic data = await _api.get('/api/notifications/usuario/$userId');
    final List<dynamic> raw = data is List ? data : const <dynamic>[];

    final List<AppNotification> items = <AppNotification>[
      for (final dynamic item in raw)
        if (item is Map<String, dynamic>) AppNotification.fromJson(item),
    ];
    items.sort(
      (AppNotification a, AppNotification b) => b.sentAt.compareTo(a.sentAt),
    );
    return items;
  }

  Future<void> markRead(String id) async {
    await _api.put('/api/notifications/$id/leer');
  }

  Future<void> markAllRead(String userId) async {
    await _api.put('/api/notifications/usuario/$userId/leer-todas');
  }
}