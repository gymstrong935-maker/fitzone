import 'package:flutter/material.dart';

import '../../core/services/workouts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../home/widgets/home_card.dart';
import '../workout/models/exercise.dart';
import 'data/plan_data.dart';
import 'widgets/day_detail_sheet.dart';
import 'widgets/day_strip.dart';
import 'widgets/mesocycle_card.dart';
import 'widgets/month_calendar.dart';
import 'widgets/recovery_card.dart';
import 'widgets/view_toggle_chip.dart';
import 'widgets/workout_day_card.dart';

enum PlanView { week, month }

/// Pantalla "Mi Plan" (pestaña de la barra inferior).
class PlanScreen extends StatefulWidget {
  const PlanScreen({
    super.key,
    required this.weekProgress,
    required this.onStartWorkout,
    required this.week,
    required this.mesocycle,
    required this.dayExercises,
    required this.sessions,
  });

  /// 7 valores (lunes a domingo): `true` = día con entrenamiento completado.
  final List<bool> weekProgress;
  final VoidCallback onStartWorkout;
  /// Los 7 días del plan generado.
  final List<WeekWorkout> week;
  final Mesocycle mesocycle;

  /// Ejercicios planificados de cada día (lunes a domingo; `null` = descanso).
  final List<List<Exercise>?> dayExercises;

  /// Entrenamientos reales guardados (de cualquier fecha).
  final List<SavedWorkout> sessions;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final int _todayIndex = todayWeekdayIndex();

  PlanView _view = PlanView.week;
  DateTime _selectedDate = DateTime.now();
  late int? _expandedDay = _todayIndex;

  /// El plan base más los entrenamientos que el usuario ya completó esta
  /// semana (los días de descanso nunca se marcan).
  List<WeekWorkout> get _workouts {
    return <WeekWorkout>[
      for (int i = 0; i < widget.week.length; i++)
        if (widget.week[i].rest)
          widget.week[i]
        else
          widget.week[i].copyWith(
            completed: widget.week[i].completed ||
                (i < widget.weekProgress.length && widget.weekProgress[i]),
          ),
    ];
  }

  void _toggleDay(int i) {
    setState(() => _expandedDay = _expandedDay == i ? null : i);
  }

  /// Fecha del día `i` (0 = lunes) de la semana actual.
  DateTime _dateOfDay(int i) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1) + i);
  }

  /// Botón "Ver": ejercicios realizados ese día (o los planificados si aún
  /// no se entrenó), con sus animaciones en miniatura.
  void _viewDay(int i) {
    final DateTime date = _dateOfDay(i);
    final List<SavedWorkout> done = <SavedWorkout>[
      for (final SavedWorkout w in widget.sessions)
        if (_sameDay(w.date.toLocal(), date)) w,
    ];
    final List<Exercise> planned = i < widget.dayExercises.length
        ? (widget.dayExercises[i] ?? const <Exercise>[])
        : const <Exercise>[];

    showDayDetailSheet(
      context,
      workout: _workouts[i],
      date: date,
      planned: planned,
      done: done,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final double top = 24 + MediaQuery.paddingOf(context).top;
    final double bottom = 96 + MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: 20),
                FadeSlideIn(
                  duration: const Duration(milliseconds: 400),
                  offsetY: 12,
                  child: MesocycleCard(mesocycle: widget.mesocycle),
                ),
                const SizedBox(height: 16),
                _buildViewToggle(),
                const SizedBox(height: 16),
                _buildViewPanel(),
                const SizedBox(height: 16),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 250),
                  duration: Duration(milliseconds: 400),
                  offsetY: 10,
                  child: RecoveryCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Cabecera ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'PLAN DE ENTRENAMIENTO',
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.40),
            letterSpacing: 1.2,
            height: 1.333,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mi Plan',
          style: AppText.display(
            size: 24,
            weight: FontWeight.w700,
            letterSpacing: -0.48,
            height: 1.333,
          ),
        ),
      ],
    );
  }

  // ── Selector Semanal | Mensual ────────────────────────────────────────────
  Widget _buildViewToggle() {
    return Row(
      children: <Widget>[
        ViewToggleChip(
          label: 'Semanal',
          selected: _view == PlanView.week,
          onTap: () => setState(() => _view = PlanView.week),
        ),
        const SizedBox(width: 8),
        ViewToggleChip(
          label: 'Mensual',
          selected: _view == PlanView.month,
          onTap: () => setState(() => _view = PlanView.month),
        ),
      ],
    );
  }

  // ── Vista que cambia con el selector ──────────────────────────────────────
  Widget _buildViewPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      reverseDuration: Duration.zero,
      layoutBuilder: (Widget? current, List<Widget> previous) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previous, if (current != null) current],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Semanal entra desde la derecha (+10), mensual desde la izquierda (-10).
        final bool isWeek = child.key == const ValueKey<String>('week');
        final double dx = isWeek ? 10 : -10;
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (BuildContext context, Widget? c) {
              return Transform.translate(
                offset: Offset((1 - animation.value) * dx, 0),
                child: c,
              );
            },
          ),
        );
      },
      child: _view == PlanView.week ? _buildWeekView() : _buildMonthView(),
    );
  }

  Widget _buildWeekView() {
    final List<WeekWorkout> workouts = _workouts;

    return Column(
      key: const ValueKey<String>('week'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DayStrip(
          workouts: workouts,
          expandedDay: _expandedDay,
          todayIndex: _todayIndex,
          onTap: _toggleDay,
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < workouts.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          FadeSlideIn(
            delay: Duration(milliseconds: i * 40),
            duration: const Duration(milliseconds: 350),
            offsetY: 8,
            child: WorkoutDayCard(
              workout: workouts[i],
              isToday: i == _todayIndex,
              isExpanded: _expandedDay == i,
              onToggle: () => _toggleDay(i),
              onStart: widget.onStartWorkout,
              onView: () => _viewDay(i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMonthView() {
    return HomeCard(
      key: const ValueKey<String>('month'),
      child: MonthCalendar(
        selected: _selectedDate,
        onSelect: (DateTime date) => setState(() => _selectedDate = date),
      ),
    );
  }
}