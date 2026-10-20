import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import '../onboarding/data/experience_levels_data.dart';
import '../onboarding/data/goals_data.dart';
import '../onboarding/models/onboarding_data.dart';
import 'data/plan_generator.dart';

const List<String> _steps = <String>[
  'Analizando tu perfil',
  'Calculando tus metas de calorías y macros',
  'Eligiendo rutinas según tu objetivo',
  'Armando tu plan semanal',
];

const double _stepStart = 0.5;
const double _stepGap = 0.85;
const double _doneAt = 4.4;

/// "Creando tu plan": animación de transición entre el onboarding y la app.
class PlanBuildingScreen extends StatefulWidget {
  const PlanBuildingScreen({
    super.key,
    required this.data,
    required this.plan,
    required this.onDone,
  });

  final OnboardingData data;
  final TrainingPlan plan;
  final VoidCallback onDone;

  @override
  State<PlanBuildingScreen> createState() => _PlanBuildingScreenState();
}

class _PlanBuildingScreenState extends State<PlanBuildingScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration elapsed) {
      final double s = elapsed.inMicroseconds / 1000000.0;
      _time.value = s;
      if (!_finished && s >= _doneAt) {
        _finished = true;
        _ticker.stop();
        if (mounted) widget.onDone();
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  String get _goalTitle {
    for (final GoalOption o in kGoals) {
      if (o.id == widget.data.goal) return o.title;
    }
    return 'Entrenamiento general';
  }

  String get _levelTitle {
    for (final ExperienceOption o in kExperienceLevels) {
      if (o.id == widget.data.experienceLevel) return o.title;
    }
    return 'Todos los niveles';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.16),
              centerX: 0.5,
              centerY: 0.35,
              radiusX: 0.7,
              radiusY: 0.45,
              fadeStop: 0.65,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: ValueListenableBuilder<double>(
                    valueListenable: _time,
                    builder: (BuildContext context, double t, Widget? _) => _buildBody(t),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: ShimmerTopBar()),
        ],
      ),
    );
  }

  Widget _buildBody(double t) {
    final double progress = (t / (_doneAt - 0.5)).clamp(0.0, 1.0).toDouble();
    final double summaryIn = Curves.easeOut.transform(((t - 3.5) / 0.6).clamp(0.0, 1.0).toDouble());
    final bool ready = t >= 3.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: SizedBox(
            width: 132,
            height: 132,
            child: CustomPaint(
              painter: _RingPainter(progress),
              child: Center(
                child: Transform.scale(
                  scale: 1 + 0.06 * math.sin(t * 5),
                  child: Icon(
                    ready ? Icons.check_rounded : Icons.fitness_center_rounded,
                    size: 46,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          ready ? '¡Tu plan está listo!' : 'Creando tu plan personalizado',
          textAlign: TextAlign.center,
          style: AppText.display(size: 24, weight: FontWeight.w700, letterSpacing: -0.4, height: 1.25),
        ),
        const SizedBox(height: 8),
        Text(
          ready
              ? widget.plan.summary
              : 'Usamos tu objetivo, nivel y hábitos para armarlo.',
          textAlign: TextAlign.center,
          style: AppText.body(size: 14, color: AppColors.whiteA(0.55), height: 1.5),
        ),
        const SizedBox(height: 28),
        for (int i = 0; i < _steps.length; i++)
          _StepRow(
            label: _steps[i],
            state: _stateOf(t, i),
            appear: Curves.easeOut.transform(((t - (_stepStart + i * _stepGap - 0.3)) / 0.4).clamp(0.0, 1.0).toDouble()),
          ),
        const SizedBox(height: 22),
        Opacity(
          opacity: summaryIn,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - summaryIn)),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _Chip(icon: Icons.track_changes_rounded, text: _goalTitle),
                _Chip(icon: Icons.bolt_rounded, text: _levelTitle),
                _Chip(
                  icon: Icons.calendar_month_rounded,
                  text: '${widget.plan.sessionsPerWeek} días por semana',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 0 = pendiente, 1 = en curso, 2 = hecho.
  int _stateOf(double t, int i) {
    final double start = _stepStart + i * _stepGap;
    if (t < start) return 0;
    if (t < start + _stepGap) return 1;
    return 2;
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - 6;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.whiteA(0.08),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: <Color>[AppColors.cyan, AppColors.teal, AppColors.cyan],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state, required this.appear});

  final String label;
  final int state;
  final double appear;

  @override
  Widget build(BuildContext context) {
    final bool done = state == 2;

    return Opacity(
      opacity: appear,
      child: Transform.translate(
        offset: Offset(-12 * (1 - appear), 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 24,
                height: 24,
                child: done
                    ? TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.4, end: 1),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.elasticOut,
                        builder: (BuildContext context, double v, Widget? _) => Transform.scale(
                          scale: v,
                          child: const Icon(Icons.check_circle_rounded, size: 24, color: Color(0xFF34D399)),
                        ),
                      )
                    : (state == 1
                        ? const Padding(
                            padding: EdgeInsets.all(3),
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.cyan),
                          )
                        : Icon(Icons.radio_button_unchecked_rounded, size: 22, color: AppColors.whiteA(0.25))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    size: 14.5,
                    weight: state == 1 ? FontWeight.w600 : FontWeight.w400,
                    color: state == 0 ? AppColors.whiteA(0.40) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cyanA(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.cyan),
          const SizedBox(width: 6),
          Text(text, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.cyan)),
        ],
      ),
    );
  }
}