/// 80000 -> "$80.000"
String formatCop(num value) {
  final String digits = value.round().abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '\$${buffer.toString()}';
}

const List<String> _shortMonths = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic',
];

/// "Hace un momento", "Hace 5 min", "Hace 3 h", "Ayer", "Hace 4 días", "12 oct".
String formatRelativeTime(DateTime date, {DateTime? now}) {
  final DateTime current = now ?? DateTime.now();
  final Duration diff = current.difference(date);

  if (diff.isNegative || diff.inSeconds < 60) return 'Hace un momento';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'Ayer';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
  return '${date.day} ${_shortMonths[date.month - 1]}';
}