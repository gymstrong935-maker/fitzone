import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/measurements_service.dart';

/// Historial de mediciones corporales (peso, estatura y medidas) que
/// alimenta la pantalla "Estadísticas".
class StatsController extends ChangeNotifier {
  StatsController({
    required MeasurementsService service,
    required this.userId,
  }) : _service = service;

  final MeasurementsService _service;
  final String userId;

  List<BodyRecord> _records = const <BodyRecord>[];
  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;
  String? _error;

  /// Mediciones guardadas, de la más vieja a la más nueva.
  List<BodyRecord> get records => _records;

  bool get loading => _loading;

  /// `true` cuando ya se consultó al servidor (aunque no hubiera datos).
  bool get loaded => _loaded;

  String? get error => _error;

  /// Descarga las mediciones del servidor.
  Future<void> load({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    if (!silent) _error = null;
    _notify();

    try {
      _records = await _service.list(userId);
      _error = null;
      _loaded = true;
    } on ApiException catch (e) {
      if (!silent) _error = e.message;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// Guarda un peso nuevo con la fecha de hoy. Conserva la estatura y las
  /// medidas de la última medición (o de [base] si todavía no hay ninguna).
  ///
  /// Lanza [ApiException] si el servidor no lo acepta.
  Future<BodyRecord> logWeight(double kg, {required BodyRecord base}) async {
    final BodyRecord template = _records.isNotEmpty ? _records.last : base;
    final BodyRecord saved =
        await _service.create(userId, template.withWeight(kg, DateTime.now()));

    _records = <BodyRecord>[..._records, saved]
      ..sort((BodyRecord a, BodyRecord b) => a.date.compareTo(b.date));
    _error = null;
    _notify();
    return saved;
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
