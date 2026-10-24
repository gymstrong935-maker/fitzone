import '../../features/onboarding/models/trainer.dart';
import '../api/api_client.dart';
import 'backend_models.dart';

String _string(Object? v) => v is String ? v : '';

List<String> _strings(Object? v) => v is List
    ? <String>[for (final Object? e in v) e.toString()]
    : const <String>[];

TrainerLevel _level(Object? v) {
  switch (v) {
    case 'elite':
      return TrainerLevel.elite;
    case 'premium':
      return TrainerLevel.premium;
    default:
      return TrainerLevel.standard;
  }
}

/// Entrenador del backend -> el modelo que usan las pantallas.
Trainer trainerFromCoach(Map<String, dynamic> json) {
  final List<String> specialties = _strings(json['especialidad']);
  final String priceDescription = _string(json['descripcionPrecio']);

  return Trainer(
    id: (json['_id'] ?? json['id'] ?? '').toString(),
    name: _string(json['nombre']),
    photo: _string(json['fotoPerfil']),
    specialty:
        specialties.isEmpty ? 'Entrenamiento personal' : specialties.join(' y '),
    experience: (json['experiencia'] as num?)?.toInt() ?? 0,
    certifications: _strings(json['certificaciones']),
    rating: (json['calificacionPromedio'] as num?)?.toDouble() ?? 0,
    description: _string(json['descripcion']),
    trainingType: _string(json['tipoEntrenamiento']),
    price: (json['precio'] as num?)?.round() ?? 0,
    priceDescription: priceDescription.isEmpty ? '/mes' : priceDescription,
    services: _strings(json['servicios']),
    level: _level(json['nivel']),
    availability: _strings(json['disponibilidad']),
  );
}

class CoachesService {
  CoachesService(this._api);

  final ApiClient _api;

  Future<List<Trainer>> fetch() async {
    final dynamic data = await _api.get('/api/coaches');
    final List<dynamic> list = data is List ? data : const <dynamic>[];

    return <Trainer>[
      for (final dynamic item in list)
        if (item is Map<String, dynamic>) trainerFromCoach(item),
    ].where((Trainer t) => t.id.isNotEmpty && t.name.isNotEmpty).toList();
  }

  /// El usuario elige a este entrenador como el suyo.
  Future<void> assign(String coachId) async {
    await _api.put('/api/coaches/$coachId/asignarme');
  }

  // ── Cambio de entrenador (lo valida el admin) ─────────────────────────────

  /// Pide cambiar de entrenador. Si el nuevo cuesta más, se genera un pago por
  /// la diferencia que el usuario debe completar.
  Future<CoachChange> requestChange(String coachId) async {
    final dynamic data = await _api.post(
      '/api/coaches/cambio',
      body: <String, dynamic>{'entrenadorId': coachId},
    );
    return CoachChange.fromJson(data as Map<String, dynamic>);
  }

  /// Última solicitud de cambio del usuario (o `null` si nunca pidió una).
  Future<CoachChange?> myChange() async {
    final dynamic data = await _api.get('/api/coaches/cambio/mia');
    return data is Map<String, dynamic> ? CoachChange.fromJson(data) : null;
  }

  Future<void> cancelChange(String id) async {
    await _api.delete('/api/coaches/cambio/$id');
  }
}
