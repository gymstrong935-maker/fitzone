import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/app_services.dart';
import '../../core/services/appointments_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/sub_screen_frame.dart';
import '../onboarding/data/trainers_repository.dart';
import '../onboarding/models/trainer.dart';

const List<String> _weekdayShort = <String>['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const List<String> _monthShort = <String>[
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic',
];

/// Pantalla "Citas": agenda una hora con tu entrenador y revisa tus citas.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({
    super.key,
    required this.userId,
    required this.trainer,
    required this.onBack,
    this.onChanged,
  });

  final String userId;
  final Trainer? trainer;
  final VoidCallback onBack;

  /// Se llama al agendar o cancelar (para refrescar las notificaciones).
  final VoidCallback? onChanged;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static Color get _cyan400 => AppColors.cyanLightText;

  final AppointmentsService _service = AppServices.instance.appointments;

  late final List<DateTime> _days = <DateTime>[
    for (int i = 0; i < 14; i++)
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day + i,
      ),
  ];

  Set<String> _booked = <String>{};
  List<Appointment> _mine = <Appointment>[];
  DateTime? _selectedDay;
  String? _selectedTime;

  bool _loading = true;
  bool _booking = false;
  String? _cancellingId;
  String _error = '';

  Trainer? get _trainer => widget.trainer;

  bool get _hasRemoteTrainer {
    final Trainer? t = _trainer;
    return t != null && TrainersRepository.isRemote(t.id);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Datos ─────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final Trainer? trainer = _trainer;
    if (!_hasRemoteTrainer || trainer == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final List<Appointment> mine = await _service.mine(widget.userId);
      final Set<String> booked = await _service.bookedSlots(trainer.id);
      if (!mounted) return;
      setState(() {
        _mine = mine.where((Appointment a) => a.isUpcoming).toList()
          ..sort((Appointment a, Appointment b) =>
              '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}'));
        _booked = booked;
        _selectedDay ??= _days.firstWhere(
          (DateTime d) => _freeTimes(d).isNotEmpty,
          orElse: () => _days.first,
        );
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  /// Horas libres de un día: dentro del horario del entrenador, sin citas
  /// ya reservadas y que todavía no hayan pasado.
  List<String> _freeTimes(DateTime day) {
    final Trainer? trainer = _trainer;
    if (trainer == null) return const <String>[];

    final DateTime now = DateTime.now();
    final String key = dateKey(day);

    return <String>[
      for (final String time in availableTimesFor(trainer.availability, day.weekday))
        if (!_booked.contains('$key $time') && _isFuture(day, time, now)) time,
    ];
  }

  bool _isFuture(DateTime day, String time, DateTime now) {
    final List<String> p = time.split(':');
    final DateTime start = DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(p[0]),
      int.parse(p[1]),
    );
    return start.isAfter(now);
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppText.body(size: 14, color: AppColors.ink)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.whiteA(0.12)),
          ),
        ),
      );
  }

  Future<void> _book() async {
    final Trainer? trainer = _trainer;
    final DateTime? day = _selectedDay;
    final String? time = _selectedTime;
    if (trainer == null || day == null || time == null || _booking) return;

    setState(() {
      _booking = true;
      _error = '';
    });

    try {
      await _service.create(
        userId: widget.userId,
        coachId: trainer.id,
        date: dateKey(day),
        time: time,
      );
      if (!mounted) return;
      _selectedTime = null;
      _toast('Cita confirmada para el ${day.day} de ${_monthShort[day.month - 1]} a las $time');
      widget.onChanged?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _booking = false);
    }

    // Recarga las citas y los horarios ocupados.
    await _load();
  }

  Future<void> _cancel(Appointment appointment) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (BuildContext ctx) => _ConfirmDialog(
        title: '¿Cancelar la cita?',
        message:
            '${appointment.date} a las ${appointment.time} con ${appointment.coachName.isEmpty ? 'tu entrenador' : appointment.coachName}.',
        confirmLabel: 'Cancelar cita',
        cancelLabel: 'Conservar',
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancellingId = appointment.id);
    try {
      await _service.cancel(appointment.id);
      if (!mounted) return;
      _toast('Cita cancelada');
      widget.onChanged?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }

    await _load();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SubScreenFrame(
      title: 'Citas',
      subtitle: 'Agenda con tu entrenador',
      onBack: widget.onBack,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasRemoteTrainer) {
      return _InfoCard(
        icon: Icons.person_search_outlined,
        title: 'Aún no tienes un entrenador asignado',
        message: _trainer == null
            ? 'Los planes Mensual y Anual incluyen entrenador personal. '
                'Elige uno en Ajustes → Cambiar Entrenador.'
            : 'Tu entrenador todavía no está sincronizado con el servidor. '
                'Vuelve a elegirlo en Ajustes → Cambiar Entrenador.',
      );
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
      );
    }

    final Trainer trainer = _trainer!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_error.isNotEmpty) ...<Widget>[
          ErrorBox(_error),
          const SizedBox(height: 12),
        ],
        _buildCoachCard(trainer),
        const SizedBox(height: 20),
        if (trainer.availability.isEmpty)
          const _InfoCard(
            icon: Icons.event_busy_outlined,
            title: 'Sin horarios publicados',
            message: 'Tu entrenador todavía no tiene horarios de atención disponibles.',
          )
        else ...<Widget>[
          _sectionTitle('Elige un día'),
          const SizedBox(height: 10),
          _buildDays(),
          const SizedBox(height: 20),
          _sectionTitle('Elige una hora'),
          const SizedBox(height: 10),
          _buildTimes(),
          const SizedBox(height: 20),
          _buildConfirmButton(),
        ],
        const SizedBox(height: 28),
        _sectionTitle('Mis próximas citas'),
        const SizedBox(height: 10),
        _buildMine(),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
    );
  }

  Widget _buildCoachCard(Trainer trainer) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanA(0.18)),
      ),
      child: Row(
        children: <Widget>[
          _CoachPhoto(url: trainer.photo, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  trainer.name,
                  style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.4),
                ),
                const SizedBox(height: 2),
                Text(
                  trainer.specialty,
                  style: AppText.body(size: 12, color: _cyan400, height: 1.333),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDays() {
    final ScrollBehavior behavior = ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
      dragDevices: <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      },
    );

    return SizedBox(
      height: 78,
      child: ScrollConfiguration(
        behavior: behavior,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(width: 8),
          itemBuilder: (BuildContext context, int index) {
            final DateTime day = _days[index];
            final bool hasSlots = _freeTimes(day).isNotEmpty;
            final bool selected = _selectedDay != null &&
                dateKey(_selectedDay!) == dateKey(day);

            return _DayChip(
              day: day,
              selected: selected,
              enabled: hasSlots,
              onTap: () => setState(() {
                _selectedDay = day;
                _selectedTime = null;
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimes() {
    final DateTime? day = _selectedDay;
    final List<String> times = day == null ? const <String>[] : _freeTimes(day);

    if (times.isEmpty) {
      return Text(
        'No hay horarios libres este día. Prueba con otro.',
        style: AppText.body(size: 13, color: AppColors.whiteA(0.45), height: 1.5),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String time in times)
          _TimeChip(
            time: time,
            selected: _selectedTime == time,
            onTap: () => setState(() => _selectedTime = time),
          ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final DateTime? day = _selectedDay;
    final String? time = _selectedTime;
    final bool ready = day != null && time != null && !_booking;

    final String label = _booking
        ? 'Reservando...'
        : (day != null && time != null)
            ? 'Confirmar · ${_weekdayShort[day.weekday - 1]} ${day.day} ${_monthShort[day.month - 1]} · $time'
            : 'Elige día y hora';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ready ? _book : null,
      child: AnimatedOpacity(
        opacity: ready ? 1 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: <Color>[AppColors.cyan, AppColors.teal],
            ),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              color: const Color(0xFF0A0A0A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMine() {
    if (_mine.isEmpty) {
      return Text(
        'No tienes citas próximas.',
        style: AppText.body(size: 13, color: AppColors.whiteA(0.45), height: 1.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < _mine.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          _AppointmentCard(
            appointment: _mine[i],
            cancelling: _cancellingId == _mine[i].id,
            onCancel: () => _cancel(_mine[i]),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _CoachPhoto extends StatelessWidget {
  const _CoachPhoto({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = ColoredBox(
      color: AppColors.whiteA(0.08),
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.5,
        color: AppColors.whiteA(0.4),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) => fallback,
              ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected
        ? const Color(0xFF0A0A0A)
        : (enabled ? AppColors.ink : AppColors.whiteA(0.25));

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.cyan, AppColors.teal],
                  )
                : null,
            color: selected ? null : AppColors.whiteA(enabled ? 0.06 : 0.03),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.whiteA(0.10),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _weekdayShort[day.weekday - 1],
                style: AppText.body(size: 12, color: textColor.withAlpha(selected ? 200 : 255)),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: AppText.display(
                  size: 20,
                  weight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              Text(
                _monthShort[day.month - 1],
                style: AppText.body(size: 11, color: textColor.withAlpha(selected ? 200 : 255)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? AppColors.cyanA(0.22) : AppColors.whiteA(0.06),
            border: Border.all(
              color: selected ? AppColors.cyanA(0.55) : AppColors.whiteA(0.10),
            ),
          ),
          child: Text(
            time,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w600,
              color: selected ? AppColors.cyanText : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.cancelling,
    required this.onCancel,
  });

  final Appointment appointment;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final DateTime? start = appointment.startsAt;
    final String when = start == null
        ? '${appointment.date} · ${appointment.time}'
        : '${_weekdayShort[start.weekday - 1]} ${start.day} ${_monthShort[start.month - 1]} · ${appointment.time}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Row(
        children: <Widget>[
          _CoachPhoto(url: appointment.coachPhoto, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  when,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.43,
                  ),
                ),
                Text(
                  appointment.coachName.isEmpty
                      ? 'Con tu entrenador'
                      : 'Con ${appointment.coachName}',
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.45),
                    height: 1.333,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: cancelling ? null : onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(239, 68, 68, 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.25)),
              ),
              child: Text(
                cancelling ? '...' : 'Cancelar',
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 32, color: AppColors.whiteA(0.45)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body(size: 13, color: AppColors.whiteA(0.50), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.whiteA(0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.display(size: 20, weight: FontWeight.w700, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body(size: 14, color: AppColors.whiteA(0.60), height: 1.43),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DialogButton(
                      label: cancelLabel,
                      background: AppColors.whiteA(0.08),
                      border: AppColors.whiteA(0.12),
                      textColor: AppColors.ink,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      background: const Color.fromRGBO(239, 68, 68, 0.12),
                      border: const Color.fromRGBO(239, 68, 68, 0.30),
                      textColor: AppColors.red,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.border,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color border;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: textColor,
            height: 1.43,
          ),
        ),
      ),
    );
  }
}