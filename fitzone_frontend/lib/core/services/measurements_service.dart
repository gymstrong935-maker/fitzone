import '../api/api_client.dart';

/// Claves de las circunferencias en el servidor (cm).
const List<String> kCircumferenceKeys = <String>[
  'brazo',
  'pecho',
  'cintura',
  'cadera',
  'muslo',
  'pantorrilla',
];

/// Claves de los pliegues cutáneos en el servidor (mm).
const List<String> kSkinfoldKeys = <String>[
  'triceps',
  'subescapular',
  'pecho',
  'abdominal',
  'muslo',
  'suprailiaco',
  'axilarMedio',
];

double? _num(Object? value) => value is num ? value.toDouble() : null;

Map<String, double> _numMap(Object? raw) {
  final Map<String, double> result = <String, double>{};
  if (raw is Map) {
    raw.forEach((Object? key, Object? value) {
      final double? v = _num(value);
      if (key is String && v != null && v > 0) result[key] = v;
    });
  }
  return result;
}

/// Una medición corporal guardada (peso, estatura y medidas) en una fecha.
class BodyRecord {
  const BodyRecord({
    required this.date,
    required this.kg,
    required this.heightM,
    this.circumferences = const <String, double>{},
    this.skinfolds = const <String, double>{},
    this.usesPounds = false,
  });

  final DateTime date;

  /// Peso en kg (el servidor siempre lo guarda en kg).
  final double kg;

  /// Estatura en metros.
  final double heightM;

  /// Circunferencias en cm (ver [kCircumferenceKeys]).
  final Map<String, double> circumferences;

  /// Pliegues cutáneos en mm (ver [kSkinfoldKeys]).
  final Map<String, double> skinfolds;

  /// `true` si la persona prefiere ver el peso en libras.
  final bool usesPounds;

  double get bmi => heightM <= 0 ? 0 : kg / (heightM * heightM);

  factory BodyRecord.fromJson(Map<String, dynamic> json) {
    return BodyRecord(
      date: DateTime.tryParse((json['fecha'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      kg: _num(json['peso']) ?? 0,
      heightM: _num(json['altura']) ?? 0,
      circumferences: _numMap(json['medidas']),
      skinfolds: _numMap(json['pliegues']),
      usesPounds: json['unidadPeso'] == 'lb',
    );
  }

  /// Cuerpo de POST /api/physical-measurements.
  Map<String, dynamic> toPayload(String userId) {
    final double peso = double.parse(kg.toStringAsFixed(1));
    final double altura = double.parse(heightM.toStringAsFixed(2));
    final double imc = bmi;

    return <String, dynamic>{
      'usuarioId': userId,
      'peso': peso,
      'altura': altura,
      if (imc > 0) 'imc': double.parse(imc.toStringAsFixed(1)),
      'unidadPeso': usesPounds ? 'lb' : 'kg',
      if (circumferences.isNotEmpty) 'medidas': circumferences,
      if (skinfolds.isNotEmpty) 'pliegues': skinfolds,
    };
  }

  /// Copia con otro peso y fecha (conserva estatura y medidas).
  BodyRecord withWeight(double newKg, DateTime at) {
    return BodyRecord(
      date: at,
      kg: newKg,
      heightM: heightM,
      circumferences: circumferences,
      skinfolds: skinfolds,
      usesPounds: usesPounds,
    );
  }
}

/// Historial de mediciones corporales del usuario.
class MeasurementsService {
  MeasurementsService(this._api);

  final ApiClient _api;

  /// Mediciones del usuario, de la más vieja a la más nueva.
  Future<List<BodyRecord>> list(String userId) async {
    final dynamic data =
        await _api.get('/api/physical-measurements/usuario/$userId');
    final List<dynamic> raw = data is List ? data : const <dynamic>[];

    final List<BodyRecord> records = <BodyRecord>[
      for (final dynamic item in raw)
        if (item is Map<String, dynamic>) BodyRecord.fromJson(item),
    ]..removeWhere((BodyRecord r) => r.kg <= 0);

    records.sort((BodyRecord a, BodyRecord b) => a.date.compareTo(b.date));
    return records;
  }

  /// Guarda una medición nueva y devuelve lo que quedó guardado.
  Future<BodyRecord> create(String userId, BodyRecord record) async {
    final dynamic data = await _api.post(
      '/api/physical-measurements',
      body: record.toPayload(userId),
    );
    if (data is Map<String, dynamic>) return BodyRecord.fromJson(data);
    return record;
  }
}
