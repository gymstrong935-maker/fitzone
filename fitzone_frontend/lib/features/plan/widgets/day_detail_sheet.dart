import 'package:flutter/material.dart';

import '../../../core/services/workouts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../workout/data/exercises_data.dart';
import '../../workout/models/exercise.dart';
import '../../workout/widgets/exercise_figure.dart';
import '../../workout/widgets/technique_sheet.dart';
import '../data/plan_data.dart';

/// Abre la tarjeta del botón "Ver" de Mi Plan.
///
/// · Si ese día ya se entrenó, muestra los ejercicios que de verdad se
///   realizaron (uno por sesión), con sus animaciones en miniatura.
/// · Si todavía no, muestra los ejercicios planificados para ese día.
Future<void> showDayDetailSheet(
  BuildContext context, {
  required WeekWorkout workout,
  required DateTime date,
  required List<Exercise> planned,
  required List<SavedWorkout> done,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xBF000000),
    constraints: const BoxConstraints(maxWidth: 512),
    builder: (BuildContext ctx) => _DayDetailSheet(
      workout: workout,
      date: date,
      planned: planned,
      done: done,
    ),
  );
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Busca en la biblioteca el ejercicio con ese nombre (para su animación).
Exercise? _findExercise(String name) {
  final String wanted = name.trim().toLowerCase();
  for (final Exercise e in kExercises) {
    if (e.name.toLowerCase() == wanted) return e;
  }
  return null;
}

/// Una fila de la lista: lo mismo sirve para lo planificado y lo realizado.
class _Row {
  const _Row({
    required this.name,
    required this.group,
    required this.sets,
    required this.reps,
    required this.exercise,
  });

  final String name;
  final String group;
  final int sets;
  final String reps;

  /// Ejercicio de la biblioteca (para la animación); `null` si no se encontró.
  final Exercise? exercise;
}

class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({
    required this.workout,
    required this.date,
    required this.planned,
    required this.done,
  });

  final WeekWorkout workout;
  final DateTime date;
  final List<Exercise> planned;
  final List<SavedWorkout> done;

  static Color get _cyan400 => AppColors.cyanLightText;
  static Color get _teal400 => AppColors.teal400;
  static Color get _orange400 => AppColors.orange;
  static Color get _green => AppColors.green;

  bool get _isDone => done.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.whiteA(0.10)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Asa.
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.whiteA(0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      _buildSummary(),
                      const SizedBox(height: 20),
                      ..._buildBody(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Encabezado ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final Color chipColor = _isDone ? _green : _cyan400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      _isDone
                          ? Icons.check_circle_outline_rounded
                          : Icons.event_note_outlined,
                      size: 12,
                      color: chipColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDone ? 'Completado' : 'Planificado',
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: chipColor,
                        height: 1.333,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workout.name,
                style: AppText.display(
                  size: 20,
                  weight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${workout.day} · ${_two(date.day)}/${_two(date.month)}',
                style: AppText.body(
                  size: 12,
                  color: AppColors.whiteA(0.45),
                  height: 1.333,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Cerrar',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whiteA(0.08),
              ),
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  // ── Resumen: minutos, ejercicios, kcal ────────────────────────────────────
  Widget _buildSummary() {
    final int minutes = _isDone
        ? done.fold<int>(0, (int sum, SavedWorkout w) => sum + w.durationMinutes)
        : workout.duration;
    final int exercises = _isDone
        ? done.fold<int>(0, (int sum, SavedWorkout w) => sum + w.exerciseCount)
        : planned.length;
    final int kcal = _isDone
        ? done.fold<int>(0, (int sum, SavedWorkout w) => sum + w.calories)
        : minutes * 8;

    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryTile(
            icon: Icons.access_time_rounded,
            color: _cyan400,
            value: '$minutes',
            label: 'minutos',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            icon: Icons.fitness_center_rounded,
            color: _teal400,
            value: '$exercises',
            label: 'ejercicios',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            icon: Icons.local_fire_department_outlined,
            color: _orange400,
            value: _isDone ? '$kcal' : '~$kcal',
            label: 'kcal',
          ),
        ),
      ],
    );
  }

  // ── Lista de ejercicios ───────────────────────────────────────────────────
  List<Widget> _buildBody(BuildContext context) {
    if (_isDone) {
      // Las sesiones del día, de la más vieja a la más nueva.
      final List<SavedWorkout> sessions = List<SavedWorkout>.of(done)
        ..sort((SavedWorkout a, SavedWorkout b) => a.date.compareTo(b.date));

      return <Widget>[
        for (int i = 0; i < sessions.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 20),
          _SectionTitle(
            icon: Icons.check_circle_outline_rounded,
            color: _green,
            text: sessions.length == 1
                ? 'Ejercicios realizados'
                : 'Sesión ${i + 1} · ${_two(sessions[i].date.hour)}:${_two(sessions[i].date.minute)}',
          ),
          const SizedBox(height: 10),
          _buildRows(
            context,
            <_Row>[
              for (final SavedExercise e in sessions[i].exercises)
                _Row(
                  name: e.name,
                  group: e.muscleGroup,
                  sets: e.sets,
                  reps: e.reps,
                  exercise: _findExercise(e.name),
                ),
            ],
            completed: true,
          ),
        ],
      ];
    }

    return <Widget>[
      _SectionTitle(
        icon: Icons.event_note_outlined,
        color: _cyan400,
        text: 'Ejercicios del día',
      ),
      const SizedBox(height: 10),
      _buildRows(
        context,
        <_Row>[
          for (final Exercise e in planned)
            _Row(
              name: e.name,
              group: e.muscleGroup,
              sets: e.sets,
              reps: e.reps,
              exercise: e,
            ),
        ],
        completed: false,
      ),
    ];
  }

  Widget _buildRows(
    BuildContext context,
    List<_Row> rows, {
    required bool completed,
  }) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.whiteA(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.whiteA(0.09)),
        ),
        child: Text(
          'No hay ejercicios registrados para este día.',
          style: AppText.body(
            size: 14,
            color: AppColors.whiteA(0.55),
            height: 1.43,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          _ExerciseTile(row: rows[i], completed: completed),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              color: color,
              height: 1.2,
            ),
          ),
          Text(
            label,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.45),
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.display(
              size: 14,
              weight: FontWeight.w700,
              height: 1.43,
            ),
          ),
        ),
      ],
    );
  }
}

/// Un ejercicio con su animación en miniatura. Al tocarlo se abre la técnica
/// completa (si el ejercicio está en la biblioteca).
class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.row, required this.completed});

  final _Row row;
  final bool completed;

  static Color get _cyan400 => AppColors.cyanLightText;

  @override
  Widget build(BuildContext context) {
    final Exercise? exercise = row.exercise;
    final String detail = <String>[
      if (row.group.isNotEmpty) row.group,
      '${row.sets} series × ${row.reps} reps',
    ].join(' · ');

    return Semantics(
      button: exercise != null,
      label: row.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: exercise == null
            ? null
            : () => showTechniqueSheet(context, exercise),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: completed
                ? const Color.fromRGBO(52, 211, 153, 0.07)
                : AppColors.whiteA(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: completed
                  ? const Color.fromRGBO(52, 211, 153, 0.25)
                  : AppColors.whiteA(0.09),
            ),
          ),
          child: Row(
            children: <Widget>[
              // Animación en miniatura.
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cyanA(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyanA(0.15)),
                ),
                child: exercise == null
                    ? Icon(
                        Icons.fitness_center_rounded,
                        size: 24,
                        color: AppColors.cyanText,
                      )
                    : ExerciseFigure(exerciseId: exercise.id, size: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      row.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 12,
                        color: _cyan400,
                        height: 1.333,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (completed)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.green,
                )
              else if (exercise != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.whiteA(0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
