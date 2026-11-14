import '../api/api_client.dart';
 
/// "2026-10-12"
String dateKey(DateTime d) {
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}
 
const List<String> _dayPrefixes = <String>['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];
const Set<String> _rangeWords = <String>{'a', 'al', 'hasta', '-'};
const Set<String> _everyDayWords = <String>{'todos', 'diario', 'diarios', 'diaria', 'siempre'};

const Map<String, String> _accents = <String, String>{
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
};

String _plain(String text) {
  final StringBuffer out = StringBuffer();
  for (final String ch in text.toLowerCase().split('')) {
    out.write(_accents[ch] ?? ch);
  }
  return out.toString();
}

class ScheduleEntry {
  const ScheduleEntry({required this.days, required this.start, required this.end});

  final List<int> days;
  final int start;
  final int end;
}

const String _timePattern = r'(\d{1,2})(?:\s*(?:[:.h]\s*(\d{2})?))?\s*(am|pm)?';
final RegExp _rangePattern = RegExp(
  '^$_timePattern\\s*(?:-|a|al|hasta|to)\\s*$_timePattern\$',
);

int? _toMinutes(String hour, String? minutes, String? meridiem) {
  int h = int.parse(hour);
  final int m = (minutes == null || minutes.isEmpty) ? 0 : int.parse(minutes);
  if (m > 59) return null;
  if (meridiem == 'pm' && h < 12) h += 12;
  if (meridiem == 'am' && h == 12) h = 0;
  if (h > 24 || (h == 24 && m > 0)) return null;
  return h * 60 + m;
}

List<int> _readDays(String text) {
  final Set<int> days = <int>{};
  int? previous;
  bool range = false;

  for (final RegExpMatch match in RegExp(r'[a-z]+|[-,/&]').allMatches(text)) {
    final String word = match.group(0)!;

    if (_rangeWords.contains(word)) {
      if (previous != null) range = true;
      continue;
    }
    if (_everyDayWords.contains(word)) {
      days.addAll(<int>[1, 2, 3, 4, 5, 6, 7]);
      previous = null;
      continue;
    }

    final int index =
        word.length >= 3 ? _dayPrefixes.indexWhere((String p) => word.startsWith(p)) : -1;
    if (index == -1) continue;

    final int day = index + 1;
    if (range && previous != null) {
      int d = previous;
      while (true) {
        days.add(d);
        if (d == day) break;
        d = (d % 7) + 1;
      }
    } else {
      days.add(day);
    }
    previous = day;
    range = false;
  }

  return days.toList()..sort();
}

ScheduleEntry? parseAvailabilityEntry(String raw) {
  final String text = _plain(raw)
      .replaceAllMapped(RegExp(r'\b([ap])\s*\.\s*m\b\.?'), (Match m) => '${m.group(1)}m')
      .replaceAll(RegExp('[–—]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final int cut = text.indexOf(RegExp(r'\d'));
  if (cut == -1) return null;

  final List<int> days = _readDays(text.substring(0, cut));
  if (days.isEmpty) return null;

  final RegExpMatch? m = _rangePattern.firstMatch(text.substring(cut).trim());
  if (m == null) return null;

  final int? end = _toMinutes(m.group(4)!, m.group(5), m.group(6));
  int? start = _toMinutes(m.group(1)!, m.group(2), m.group(3));

  if (m.group(3) == null && m.group(6) != null && end != null) {
    final int? inherited = _toMinutes(m.group(1)!, m.group(2), m.group(6));
    if (inherited != null && inherited < end) start = inherited;
  }

  if (start == null || end == null || end < start + 60) return null;
  return ScheduleEntry(days: days, start: start, end: end);
}

List<String> availableTimesFor(List<String> availability, int weekday) {
  final Set<String> times = <String>{};

  for (final String entry in availability) {
    final ScheduleEntry? parsed = parseAvailabilityEntry(entry);
    if (parsed == null || !parsed.days.contains(weekday)) continue;

    for (int t = parsed.start; t + 60 <= parsed.end; t += 60) {
      final String h = (t ~/ 60).toString().padLeft(2, '0');
      final String min = (t % 60).toString().padLeft(2, '0');
      times.add('$h:$min');
    }
  }

  final List<String> sorted = times.toList()..sort();
  return sorted;
}

 
final RegExp _availabilityPattern = RegExp(
  r'^\s*([^\s\d]+)\s+(\d{1,2}):(\d{2})\s*(?:-|–|—|a|al|to)\s*(\d{1,2}):(\d{2})\s*$',
);
 

 
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