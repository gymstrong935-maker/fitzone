import '../api/api_client.dart';
import 'chat_service.dart';

class SupportReply {
  const SupportReply({
    required this.fromAdmin,
    required this.message,
    required this.date,
  });

  final bool fromAdmin;
  final String message;
  final DateTime date;
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.updatedAt,
    required this.replies,
  });

  final String id;
  final String subject;
  final String message;

  /// abierto | en_proceso | cerrado
  final String status;
  final DateTime updatedAt;
  final List<SupportReply> replies;

  bool get isClosed => status == 'cerrado';
  bool get hasAdminReply => replies.any((SupportReply r) => r.fromAdmin);

  String get statusLabel {
    switch (status) {
      case 'en_proceso':
        return 'En proceso';
      case 'cerrado':
        return 'Cerrada';
      default:
        return 'Abierta';
    }
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final Object? raw = json['respuestas'];
    return SupportTicket(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      subject: (json['asunto'] ?? '').toString(),
      message: (json['mensaje'] ?? '').toString(),
      status: (json['estado'] ?? 'abierto').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      replies: raw is List
          ? <SupportReply>[
              for (final Object? r in raw)
                if (r is Map<String, dynamic>)
                  SupportReply(
                    fromAdmin: r['autor'] == 'admin',
                    message: (r['mensaje'] ?? '').toString(),
                    date: DateTime.tryParse((r['fecha'] ?? '').toString())?.toLocal() ??
                        DateTime.now(),
                  ),
            ]
          : const <SupportReply>[],
    );
  }
}

class SupportService {
  SupportService(this._api);

  final ApiClient _api;

  Future<SupportTicket> create({
    required String subject,
    required String message,
    required List<ChatTurn> transcript,
  }) async {
    final dynamic data = await _api.post(
      '/api/support',
      body: <String, dynamic>{
        'asunto': subject,
        'mensaje': message,
        'transcripcion': <Map<String, String>>[
          for (final ChatTurn t in transcript)
            <String, String>{'rol': t.role, 'contenido': t.content},
        ],
      },
    );
    return SupportTicket.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SupportTicket>> mine() async {
    final dynamic data = await _api.get('/api/support/mios');
    final List<dynamic> raw = data is List ? data : const <dynamic>[];
    return <SupportTicket>[
      for (final dynamic t in raw)
        if (t is Map<String, dynamic>) SupportTicket.fromJson(t),
    ];
  }

  Future<SupportTicket> addMessage(String id, String message) async {
    final dynamic data = await _api.post(
      '/api/support/$id/mensaje',
      body: <String, dynamic>{'mensaje': message},
    );
    return SupportTicket.fromJson(data as Map<String, dynamic>);
  }
}