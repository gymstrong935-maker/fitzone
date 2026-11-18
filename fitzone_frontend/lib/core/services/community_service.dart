import '../api/api_client.dart';

String _str(Object? v) => v == null ? '' : v.toString();

int _int(Object? v) => v is num ? v.round() : 0;

DateTime _date(Object? v) =>
    DateTime.tryParse(_str(v))?.toLocal() ?? DateTime.now();

/// Quien publica o comenta (el servidor solo envía "Juan P.", nunca el nombre completo).
class CommunityAuthor {
  const CommunityAuthor({
    required this.id,
    required this.name,
    required this.initials,
    required this.photo,
  });

  final String id;
  final String name;
  final String initials;
  final String photo;

  factory CommunityAuthor.fromJson(Object? raw) {
    final Map<String, dynamic> json =
        raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final String name = _str(json['nombre']);
    return CommunityAuthor(
      id: _str(json['_id']),
      name: name.isEmpty ? 'Usuario' : name,
      initials: _str(json['iniciales']).isEmpty ? 'U' : _str(json['iniciales']),
      photo: _str(json['fotoPerfil']),
    );
  }
}

class SharedExercise {
  const SharedExercise({
    required this.name,
    required this.sets,
    required this.reps,
  });

  final String name;
  final int sets;
  final String reps;

  factory SharedExercise.fromJson(Map<String, dynamic> json) => SharedExercise(
        name: _str(json['nombre']),
        sets: _int(json['series']),
        reps: _str(json['repeticiones']),
      );
}

/// El entrenamiento que se adjunta a una publicación.
class SharedWorkout {
  const SharedWorkout({
    required this.title,
    required this.durationMinutes,
    required this.calories,
    required this.exercises,
  });

  final String title;
  final int durationMinutes;
  final int calories;
  final List<SharedExercise> exercises;

  factory SharedWorkout.fromJson(Map<String, dynamic> json) {
    final Object? raw = json['ejercicios'];
    return SharedWorkout(
      title: _str(json['titulo']).isEmpty ? 'Entrenamiento' : _str(json['titulo']),
      durationMinutes: _int(json['duracionMinutos']),
      calories: _int(json['calorias']),
      exercises: raw is List
          ? <SharedExercise>[
              for (final Object? e in raw)
                if (e is Map<String, dynamic>) SharedExercise.fromJson(e),
            ]
          : const <SharedExercise>[],
    );
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.text,
    required this.workout,
    required this.likes,
    required this.liked,
    required this.comments,
    required this.createdAt,
    required this.mine,
  });

  final String id;
  final CommunityAuthor author;
  final String text;
  final SharedWorkout? workout;
  final int likes;
  final bool liked;
  final int comments;
  final DateTime createdAt;

  /// `true` si la publicación es del usuario (puede eliminarla).
  final bool mine;

  CommunityPost copyWith({int? likes, bool? liked, int? comments}) {
    return CommunityPost(
      id: id,
      author: author,
      text: text,
      workout: workout,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
      comments: comments ?? this.comments,
      createdAt: createdAt,
      mine: mine,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final Object? workout = json['entrenamiento'];
    return CommunityPost(
      id: _str(json['_id'] ?? json['id']),
      author: CommunityAuthor.fromJson(json['autor']),
      text: _str(json['texto']),
      workout: workout is Map<String, dynamic>
          ? SharedWorkout.fromJson(workout)
          : null,
      likes: _int(json['likes']),
      liked: json['meGusta'] == true,
      comments: _int(json['comentarios']),
      createdAt: _date(json['fecha']),
      mine: json['esMio'] == true,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.mine,
    required this.canDelete,
  });

  final String id;
  final CommunityAuthor author;
  final String text;
  final DateTime createdAt;
  final bool mine;
  final bool canDelete;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: _str(json['_id'] ?? json['id']),
      author: CommunityAuthor.fromJson(json['autor']),
      text: _str(json['texto']),
      createdAt: _date(json['fecha']),
      mine: json['esMio'] == true,
      canDelete: json['puedeBorrar'] == true,
    );
  }
}

class CommunityService {
  CommunityService(this._api);

  final ApiClient _api;

  /// Publicaciones, de la más nueva a la más vieja. Para la página siguiente,
  /// pasa el id de la última publicación recibida en [before].
  Future<List<CommunityPost>> feed({String? before, int limit = 15}) async {
    final String query = 'limite=$limit${before == null ? '' : '&antes=$before'}';
    final dynamic data = await _api.get('/api/community?$query');
    final List<dynamic> raw = data is List ? data : const <dynamic>[];

    return <CommunityPost>[
      for (final dynamic item in raw)
        if (item is Map<String, dynamic>) CommunityPost.fromJson(item),
    ];
  }

  /// Publica un mensaje, un entrenamiento guardado, o ambos.
  Future<CommunityPost> publish({String text = '', String? workoutId}) async {
    final dynamic data = await _api.post(
      '/api/community',
      body: <String, dynamic>{
        if (text.trim().isNotEmpty) 'texto': text.trim(),
        if (workoutId != null && workoutId.isNotEmpty) 'entrenamientoId': workoutId,
      },
    );
    return CommunityPost.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await _api.delete('/api/community/$postId');
  }

  /// Da o quita el me gusta. Devuelve cómo quedó en el servidor.
  Future<({bool liked, int likes})> toggleLike(String postId) async {
    final dynamic data = await _api.post('/api/community/$postId/like');
    final Map<String, dynamic> json =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return (liked: json['meGusta'] == true, likes: _int(json['likes']));
  }

  Future<List<CommunityComment>> comments(String postId) async {
    final dynamic data = await _api.get('/api/community/$postId/comentarios');
    final List<dynamic> raw = data is List ? data : const <dynamic>[];

    return <CommunityComment>[
      for (final dynamic item in raw)
        if (item is Map<String, dynamic>) CommunityComment.fromJson(item),
    ];
  }

  Future<CommunityComment> addComment(String postId, String text) async {
    final dynamic data = await _api.post(
      '/api/community/$postId/comentarios',
      body: <String, dynamic>{'texto': text.trim()},
    );
    return CommunityComment.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/api/community/$postId/comentarios/$commentId');
  }
}
