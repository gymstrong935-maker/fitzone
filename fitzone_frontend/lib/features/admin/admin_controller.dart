import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/admin_service.dart';
import 'widgets/admin_widgets.dart';

class AdminController extends ChangeNotifier {
  AdminController(this._service);

  final AdminService _service;

  Map<String, dynamic> stats = const <String, dynamic>{};
  bool loading = false;
  String? error;

  Timer? _timer;
  bool _disposed = false;

  int get pendingPayments => asNum(asMap(stats['suscripciones'])['pendientes']).toInt();
  int get openTickets => asNum(stats['ticketsAbiertos']).toInt();
  int get pendingAccounts => asNum(asMap(stats['usuarios'])['pendientes']).toInt();

  void start() {
    refresh(silent: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => refresh(silent: true));
  }

  Future<void> refresh({bool silent = false}) async {
    if (loading) return;
    loading = true;
    if (!silent) error = null;
    _notify();

    try {
      stats = await _service.stats();
      error = null;
    } on ApiException catch (e) {
      if (!silent) error = e.message;
    } finally {
      loading = false;
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