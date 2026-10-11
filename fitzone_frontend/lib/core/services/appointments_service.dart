import '../api/api_client.dart';

/// "2026-10-12"
String dateKey(DateTime d) {
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

const Map<String, int> _dayNames = <String, int>{
  'lunes': 1,
  'martes': 2,
  'miércoles': 3,
  'miercoles': 3,
  'jueves': 4,
  'viernes': 5,
  'sábado': 6,
  'sabado': 6,
  'domingo': 7,
};

final RegExp _availabilityPattern = RegExp(
  r'^\s*([^\s\d]+)\s+(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$',
);

/// Horas de inicio ("06:00", "07:00"...) disponibles en un día de la semana
/// (lunes = 1 ... domingo = 7), a partir de horarios como "lunes 06:00-12:00".
/// Cada cita dura 1 hora.
List<String> availableTimesFor(List<String> availability, int weekday) {
  final Set<String> times = <String>{};

  for (final String entry in availability) {
    final RegExpMatch? m = _availabilityPattern.firstMatch(entry.toLowerCase());
    if (m == null) continue;
    if (_dayNames[m.group(1)] != weekday) continue;

    final int start = int.parse(m.group(2)!) * 60 + int.parse(m.group(3)!);
    final int end = int.parse(m.group(4)!) * 60 + int.parse(m.group(5)!);

    for (int t = start; t + 60 <= end; t += 60) {
      final String h = (t ~/ 60).toString().padLeft(2, '0');
      final String min = (t % 60).toString().padLeft(2, '0');
      times.add('$h:$min');
    }
  }

  final List<String> sorted = times.toList()..sort();
  return sorted;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.coachPhoto,
    required this.date,
    required this.time,
    required this.status,
  });

  final String id;
  final String coachId;
  final String coachName;
  final String coachPhoto;

  /// "2026-10-12"
  final String date;

  /// "18:00"
  final String time;

  /// confirmada | cancelada
  final String status;

  DateTime? get startsAt => DateTime.tryParse('${date}T$time:00');

  bool get isUpcoming {
    final DateTime? start = startsAt;
    return status == 'confirmada' && start != null && start.isAfter(DateTime.now());
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final Object? coach = json['entrenadorId'];
    String coachId = '';
    String coachName = '';
    String coachPhoto = '';

    if (coach is Map<String, dynamic>) {
      coachId = (coach['_id'] ?? '').toString();
      coachName = (coach['nombre'] ?? '').toString();
      coachPhoto = (coach['fotoPerfil'] ?? '').toString();
    } else {
      coachId = coach?.toString() ?? '';
    }

    return Appointment(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      coachId: coachId,
      coachName: coachName,
      coachPhoto: coachPhoto,
      date: (json['fecha'] ?? '').toString(),
      time: (json['hora'] ?? '').toString(),
      status: (json['estado'] ?? 'confirmada').toString(),
    );
  }
}

class AppointmentsService {
  AppointmentsService(this._api);

  final ApiClient _api;

  /// Horarios ya ocupados de un entrenador, como "2026-10-12 18:00".
  Future<Set<String>> bookedSlots(String coachId) async {
    final dynamic data = await _api.get('/api/appointments/entrenador/$coachId');
    final List<dynamic> list = data is List ? data : const <dynamic>[];

    return <String>{
      for (final dynamic item in list)
        if (item is Map<String, dynamic>) '${item['fecha']} ${item['hora']}',
    };
  }

  /// Citas del usuario (próximas primero).
  Future<List<Appointment>> mine(String userId) async {
    final dynamic data = await _api.get('/api/appointments/usuario/$userId');
    final List<dynamic> list = data is List ? data : const <dynamic>[];

    return <Appointment>[
      for (final dynamic item in list)
        if (item is Map<String, dynamic>) Appointment.fromJson(item),
    ];
  }

  Future<void> create({
    required String userId,
    required String coachId,
    required String date,
    required String time,
  }) async {
    await _api.post(
      '/api/appointments',
      body: <String, dynamic>{
        'usuarioId': userId,
        'entrenadorId': coachId,
        'fecha': date,
        'hora': time,
      },
    );
  }

  Future<void> cancel(String appointmentId) async {
    await _api.put('/api/appointments/$appointmentId/cancelar');
  }
}