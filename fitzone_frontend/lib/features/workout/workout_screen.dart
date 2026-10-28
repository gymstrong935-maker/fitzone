import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/sound_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'models/exercise.dart';
import 'models/workout_log.dart';
import 'widgets/active_exercise_view.dart';
import 'widgets/rest_timer_view.dart';
import 'widgets/workout_summary_view.dart';

/// Entrenamiento completo: ejercicio activo -> descanso -> ... -> resumen.
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.exercises,
    required this.onComplete,
    required this.onCancel,
  });

  final List<Exercise> exercises;
  final ValueChanged<WorkoutLog> onComplete;
  final VoidCallback onCancel;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? _timer;

  int _index = 0;
  bool _resting = false;
  int _restTotal = 0;
  int _restLeft = 0;
  int _workoutSeconds = 0;
  int _completedCount = 0;
  bool _showSummary = false;
  bool _soundOn = SoundService.instance.enabled;

  /// Segundos que suma el botón "+15 s" del descanso.
  static const int _extraRestSeconds = 15;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    unawaited(_initSound());
  }

  /// Lee si el usuario había silenciado los sonidos y avisa que empieza.
  Future<void> _initSound() async {
    await SoundService.instance.load();
    if (!mounted) return;
    setState(() => _soundOn = SoundService.instance.enabled);
    unawaited(SoundService.instance.play(FzSound.start));
  }

  Future<void> _toggleSound() async {
    final bool next = !_soundOn;
    setState(() => _soundOn = next);
    await SoundService.instance.setEnabled(next);
    if (next) unawaited(SoundService.instance.play(FzSound.tap));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Un tic por segundo: avanza el cronómetro general (hasta el resumen) y la
  /// cuenta regresiva del descanso.
  void _tick(Timer timer) {
    if (!mounted) return;

    FzSound? sound;
    setState(() {
      if (!_showSummary) _workoutSeconds++;
      if (_resting) {
        _restLeft--;
        if (_restLeft <= 0) {
          _restLeft = 0;
          _resting = false;
          sound = FzSound.go; // se acabó el descanso: a trabajar
        } else if (_restLeft <= kRestWarningSeconds) {
          sound = FzSound.tick; // cuenta regresiva en rojo
        }
      }
    });

    final FzSound? toPlay = sound;
    if (toPlay != null) unawaited(SoundService.instance.play(toPlay));
  }

  void _completeExercise() {
    final Exercise current = widget.exercises[_index];
    _completedCount++;

    if (_index < widget.exercises.length - 1) {
      unawaited(SoundService.instance.play(FzSound.complete));
      setState(() {
        _restTotal = current.rest;
        _restLeft = current.rest;
        _resting = true;
        _index++;
      });
    } else {
      unawaited(SoundService.instance.play(FzSound.finish));
      setState(() => _showSummary = true);
    }
  }

  void _skipRest() {
    unawaited(SoundService.instance.play(FzSound.tap));
    setState(() {
      _resting = false;
      _restLeft = 0;
    });
  }

  void _extendRest() {
    unawaited(SoundService.instance.play(FzSound.tap));
    setState(() {
      _restTotal += _extraRestSeconds;
      _restLeft += _extraRestSeconds;
    });
  }

  Future<void> _confirmExit() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (BuildContext ctx) => const _ExitDialog(),
    );
    if (leave == true) widget.onCancel();
  }

  void _save(
    int? restingHeartRate,
    FatigueLevel fatigue,
    SorenessLevel soreness,
  ) {
    final DateTime now = DateTime.now();
    widget.onComplete(
      WorkoutLog(
        workoutId: 'workout-${now.millisecondsSinceEpoch}',
        date: now,
        // Minutos reales, redondeados (y al menos 1 si hubo entrenamiento).
        duration: math.max(1, (_workoutSeconds / 60).round()),
        calories: (_workoutSeconds / 60 * 8).round(),
        restingHeartRate: restingHeartRate,
        fatigue: fatigue,
        soreness: soreness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;

    if (_showSummary) {
      body = WorkoutSummaryView(
        key: const ValueKey<String>('summary'),
        workoutSeconds: _workoutSeconds,
        completed: _completedCount,
        total: widget.exercises.length,
        onSave: _save,
      );
    } else if (_resting) {
      body = RestTimerView(
        key: const ValueKey<String>('rest'),
        secondsLeft: _restLeft,
        totalSeconds: _restTotal,
        nextExercise: widget.exercises[_index],
        onSkip: _skipRest,
        onExtend: _extendRest,
        soundOn: _soundOn,
        onToggleSound: () => unawaited(_toggleSound()),
      );
    } else {
      body = ActiveExerciseView(
        key: ValueKey<String>('active-$_index'),
        exercise: widget.exercises[_index],
        index: _index,
        total: widget.exercises.length,
        workoutSeconds: _workoutSeconds,
        onCancel: _confirmExit,
        onComplete: _completeExercise,
        soundOn: _soundOn,
        onToggleSound: () => unawaited(_toggleSound()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: body,
      ),
    );
  }
}

/// Confirmación al pulsar la X del entrenamiento.
class _ExitDialog extends StatelessWidget {
  const _ExitDialog();

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
                '¿Salir del entrenamiento?',
                textAlign: TextAlign.center,
                style: AppText.display(
                  size: 20,
                  weight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Perderás el progreso de esta sesión.',
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 14,
                  color: AppColors.whiteA(0.60),
                  height: 1.43,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DialogButton(
                      label: 'Seguir',
                      background: AppColors.whiteA(0.08),
                      border: AppColors.whiteA(0.12),
                      textColor: AppColors.ink,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: 'Salir',
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