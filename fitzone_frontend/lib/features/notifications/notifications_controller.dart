import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/notifications_service.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController({
    required NotificationsService service,
    required this.userId,
  }) : _service = service;

  final NotificationsService _service;
  final String userId;

  List<AppNotification> _items = const <AppNotification>[];
  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;
  String? _error;
  Timer? _timer;

  List<AppNotification> get items => _items;
  bool get loading => _loading;

  /// `true` cuando ya se cargó la lista al menos una vez.
  bool get loaded => _loaded;
  String? get error => _error;

  int get unreadCount => _items.where((AppNotification n) => !n.read).length;

  /// Carga la lista y la refresca cada minuto mientras la app esté abierta.
  void start() {
    refresh(silent: true);
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => refresh(silent: true),
    );
  }

  /// `silent`: no muestra errores (para el refresco automático).
  Future<void> refresh({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    if (!silent) _error = null;
    _notify();

    try {
      _items = await _service.list(userId);
      _error = null;
      _loaded = true;
    } on ApiException catch (e) {
      if (!silent) _error = e.message;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// Marca una notificación como leída (se ve al instante; si el servidor
  /// falla, se deshace).
  Future<void> markRead(String id) async {
    final int index = _items.indexWhere((AppNotification n) => n.id == id);
    if (index < 0 || _items[index].read) return;

    final AppNotification previous = _items[index];
    _items = List<AppNotification>.of(_items)
      ..[index] = previous.copyWith(read: true);
    _notify();

    try {
      await _service.markRead(id);
    } on ApiException catch (e) {
      final int again = _items.indexWhere((AppNotification n) => n.id == id);
      if (again >= 0) {
        _items = List<AppNotification>.of(_items)..[again] = previous;
      }
      _error = e.message;
      _notify();
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;

    final List<AppNotification> previous = _items;
    _items = <AppNotification>[
      for (final AppNotification n in previous) n.copyWith(read: true),
    ];
    _error = null;
    _notify();

    try {
      await _service.markAllRead(userId);
    } on ApiException catch (e) {
      _items = previous;
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
    _timer?.cancel();
    super.dispose();
  }
}