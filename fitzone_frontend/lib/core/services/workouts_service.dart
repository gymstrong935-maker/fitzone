import 'dart:math' as math;

import '../api/api_client.dart';

class SavedExercise {
  const SavedExercise({
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
  });

  final String name;
  final String muscleGroup;
  final int sets;

  /// Rango de repeticiones, p. ej. "8-10".
  final String reps;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nombre': name,
        'grupoMuscular': muscleGroup,
        'series': sets,
        'repeticiones': reps,
      };

  factory SavedExercise.fromJson(Map<String, dynamic> json) {
    return SavedExercise(
      name: (json['nombre'] ?? '').toString(),
      muscleGroup: (json['grupoMuscular'] ?? '').toString(),
      sets: (json['series'] as num?)?.toInt() ?? 0,
      reps: (json['repeticiones'] ?? '').toString(),
    );
  }
}

/// Un entrenamiento terminado (guardado en el servidor o esperando enviarse).
class SavedWorkout {
  const SavedWorkout({
    required this.id,
    required this.clientId,
    required this.date,
    required this.durationMinutes,
    required this.calories,
    required this.exercises,
    required this.fatigue,
    required this.soreness,
    this.restingHeartRate,
    this.pending = false,
  });

  /// Id del servidor ("" mientras no se haya enviado).
  final String id;

  /// Id generado en el dispositivo (evita duplicados al reintentar).
  final String clientId;
  final DateTime date;
  final int durationMinutes;
  final int calories;
  final List<SavedExercise> exercises;

  /// none | moderate | fatigued | high | veryHigh
  final String fatigue;

  /// none | light | moderate | intense
  final String soreness;
  final int? restingHeartRate;

  /// `true` si todavía no llegó al servidor.
  final bool pending;

  int get exerciseCount => exercises.length;

  /// Nombre corto: los grupos musculares trabajados.
  String get title {
    final List<String> groups = <String>[];
    for (final SavedExercise e in exercises) {
      if (e.muscleGroup.isNotEmpty && !groups.contains(e.muscleGroup)) {
        groups.add(e.muscleGroup);
      }
    }
    if (groups.isEmpty) return 'Entrenamiento';
    final String shown = groups.take(3).join(' · ');
    return groups.length > 3 ? '$shown…' : shown;
  }

  SavedWorkout copyWith({String? id, bool? pending}) {
    return SavedWorkout(
      id: id ?? this.id,
      clientId: clientId,
      date: date,
      durationMinutes: durationMinutes,
      calories: calories,
      exercises: exercises,
      fatigue: fatigue,
      soreness: soreness,
      restingHeartRate: restingHeartRate,
      pending: pending ?? this.pending,
    );
  }

  /// Cuerpo de POST /api/workouts.
  Map<String, dynamic> toPayload(String userId) {
    final int? hr = restingHeartRate;
    return <String, dynamic>{
      'usuarioId': userId,
      'clienteId': clientId,
      'fecha': date.toUtc().toIso8601String(),
      'duracionMinutos': math.min(math.max(durationMinutes, 0), 600),
      'calorias': math.min(math.max(calories, 0), 5000),
      'ejercicios': <Map<String, dynamic>>[
        for (final SavedExercise e in exercises) e.toJson(),
      ],
      'fatiga': fatigue,
      'agujetas': soreness,
      if (hr != null && hr >= 20 && hr <= 250) 'pulsacionesReposo': hr,
    };
  }

  factory SavedWorkout.fromJson(Map<String, dynamic> json) {
    final Object? rawExercises = json['ejercicios'];
    return SavedWorkout(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      clientId: (json['clienteId'] ?? '').toString(),
      date: DateTime.tryParse((json['fecha'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      durationMinutes: (json['duracionMinutos'] as num?)?.round() ?? 0,
      calories: (json['calorias'] as num?)?.round() ?? 0,
      exercises: rawExercises is List
          ? <SavedExercise>[
              for (final Object? e in rawExercises)
                if (e is Map<String, dynamic>) SavedExercise.fromJson(e),
            ]
          : const <SavedExercise>[],
      fatigue: (json['fatiga'] ?? 'moderate').toString(),
      soreness: (json['agujetas'] ?? 'light').toString(),
      restingHeartRate: (json['pulsacionesReposo'] as num?)?.toInt(),
    );
  }

  // ── Para la cola de envíos pendientes (se guarda en el dispositivo) ──────

  Map<String, dynamic> toStorageJson() => <String, dynamic>{
        'clientId': clientId,
        'date': date.toUtc().toIso8601String(),
        'duration': durationMinutes,
        'calories': calories,
        'exercises': <Map<String, dynamic>>[
          for (final SavedExercise e in exercises) e.toJson(),
        ],
        'fatigue': fatigue,
        'soreness': soreness,
        'hr': restingHeartRate,
      };

  factory SavedWorkout.fromStorageJson(Map<String, dynamic> json) {
    final Object? rawExercises = json['exercises'];
    return SavedWorkout(
      id: '',
      clientId: (json['clientId'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      durationMinutes: (json['duration'] as num?)?.round() ?? 0,
      calories: (json['calories'] as num?)?.round() ?? 0,
      exercises: rawExercises is List
          ? <SavedExercise>[
              for (final Object? e in rawExercises)
                if (e is Map<String, dynamic>) SavedExercise.fromJson(e),
            ]
          : const <SavedExercise>[],
      fatigue: (json['fatigue'] ?? 'moderate').toString(),
      soreness: (json['soreness'] ?? 'light').toString(),
      restingHeartRate: (json['hr'] as num?)?.toInt(),
      pending: true,
    );
  }
}

class WorkoutsService {
  WorkoutsService(this._api);

  final ApiClient _api;

  Future<List<SavedWorkout>> list(String userId) async {
    final dynamic data = await _api.get('/api/workouts/usuario/$userId');
    final List<dynamic> raw = data is List ? data : const <dynamic>[];

    return <SavedWorkout>[
      for (final dynamic item in raw)
        if (item is Map<String, dynamic>) SavedWorkout.fromJson(item),
    ];
  }

  Future<SavedWorkout> create(String userId, SavedWorkout workout) async {
    final dynamic data =
        await _api.post('/api/workouts', body: workout.toPayload(userId));
    return SavedWorkout.fromJson(data as Map<String, dynamic>);
  }
}