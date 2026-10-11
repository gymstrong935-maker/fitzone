import '../api/api_client.dart';
import '../api/api_exception.dart';

/// Un mensaje de la conversación que se envía al servidor como contexto.
class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  /// "user" o "assistant"
  final String role;
  final String content;
}

class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  /// Envía [message] (con los últimos mensajes como contexto) y devuelve la
  /// respuesta del asistente.
  Future<String> send({
    required String message,
    required List<ChatTurn> history,
  }) async {
    final dynamic data = await _api.post(
      '/api/chat',
      body: <String, dynamic>{
        'mensaje': message,
        'historial': <Map<String, String>>[
          for (final ChatTurn t in history)
            <String, String>{'rol': t.role, 'contenido': t.content},
        ],
      },
    );

    final Object? reply = data is Map<String, dynamic> ? data['respuesta'] : null;
    if (reply is String && reply.trim().isNotEmpty) return reply;
    throw const ApiException('El asistente no pudo responder. Inténtalo de nuevo.');
  }
}