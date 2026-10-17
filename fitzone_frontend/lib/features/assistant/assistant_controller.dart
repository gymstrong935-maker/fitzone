import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/chat_service.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.isError = false,
    this.isWelcome = false,
  });

  final int id;
  final bool fromUser;
  final String text;

  /// Mensaje de "no pude responder" (se muestra con botones de ayuda).
  final bool isError;
  final bool isWelcome;
}

/// Quita el formato markdown que a veces devuelve el modelo.
String cleanAssistantText(String raw) {
  String text = raw;
  text = text.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (Match m) => m[1] ?? '');
  text = text.replaceAllMapped(RegExp(r'__(.+?)__'), (Match m) => m[1] ?? '');
  text = text.replaceAll('`', '');
  text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
  text = text.replaceAllMapped(
    RegExp(r'^\s*[-*]\s+', multiLine: true),
    (Match m) => '• ',
  );
  return text.trim();
}

/// Mensaje amable según el tipo de fallo (nunca un texto técnico).
String _friendlyMessage(Object error) {
  if (error is ApiException && error.isNetwork) {
    return 'Parece que no tengo conexión con el servidor en este momento. Revisa tu internet e inténtalo de nuevo.';
  }
  return 'Estoy teniendo problemas para responder ahora mismo. Inténtalo de nuevo en unos segundos o toca «Hablar con una persona».';
}

class AssistantController extends ChangeNotifier {
  AssistantController({required ChatService service, required String userName})
      : _service = service {
    final String first = userName.trim().split(' ').first;
    _messages.add(
      ChatMessage(
        id: _nextId++,
        fromUser: false,
        isWelcome: true,
        text:
            '¡Hola${first.isEmpty ? '' : ', $first'}! Soy el asistente de FitZone. '
            'Puedo ayudarte con planes, entrenadores, citas, tu cuenta y el uso de la app.',
      ),
    );
  }

  final ChatService _service;
  final List<ChatMessage> _messages = <ChatMessage>[];

  int _nextId = 0;
  bool _sending = false;
  bool _disposed = false;
  String? _failedText;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get sending => _sending;

  /// `true` mientras solo está el mensaje de bienvenida.
  bool get isFresh => _messages.length == 1;

  /// Los últimos mensajes reales (sin bienvenida ni avisos de fallo), para
  /// adjuntarlos a una solicitud de soporte.
  List<ChatTurn> get transcript {
    final List<ChatTurn> all = _realTurns();
    return all.length > 12 ? all.sublist(all.length - 12) : all;
  }

  List<ChatTurn> _realTurns() => <ChatTurn>[
        for (final ChatMessage m in _messages)
          if (!m.isWelcome && !m.isError)
            ChatTurn(role: m.fromUser ? 'user' : 'assistant', content: m.text),
      ];

  Future<void> send(String text) async {
    final String clean = text.trim();
    if (clean.isEmpty || _sending) return;

    // Contexto: los últimos mensajes reales.
    final List<ChatTurn> history = _realTurns();
    final List<ChatTurn> recent =
        history.length > 8 ? history.sublist(history.length - 8) : history;

    _messages.add(ChatMessage(id: _nextId++, fromUser: true, text: clean));
    _sending = true;
    _failedText = null;
    _notify();

    try {
      final String reply = await _service.send(message: clean, history: recent);
      final String shown = cleanAssistantText(reply);
      _messages.add(
        ChatMessage(
          id: _nextId++,
          fromUser: false,
          text: shown.isEmpty
              ? 'No tengo una respuesta para eso. Toca «Hablar con una persona» y el equipo te ayudará.'
              : shown,
        ),
      );
    } catch (e) {
      _failedText = clean;
      _messages.add(
        ChatMessage(
          id: _nextId++,
          fromUser: false,
          text: _friendlyMessage(e),
          isError: true,
        ),
      );
    } finally {
      _sending = false;
      _notify();
    }
  }

  /// Vuelve a enviar el último mensaje que falló.
  Future<void> retry() async {
    final String? text = _failedText;
    if (text == null || _sending) return;

    // Quita el aviso y el mensaje que lo causó para no duplicarlo.
    if (_messages.isNotEmpty && _messages.last.isError) _messages.removeLast();
    if (_messages.isNotEmpty && _messages.last.fromUser) _messages.removeLast();
    _failedText = null;
    _notify();

    await send(text);
  }

  /// Empieza una conversación nueva (conserva solo la bienvenida).
  void clear() {
    if (_sending) return;
    _messages.removeWhere((ChatMessage m) => !m.isWelcome);
    _failedText = null;
    _notify();
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