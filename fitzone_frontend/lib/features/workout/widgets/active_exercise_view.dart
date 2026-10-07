import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/ellipse_glow.dart';
import '../models/exercise.dart';
import '../workout_format.dart';
import 'exercise_figure.dart';
import 'technique_sheet.dart';

/// Vista del ejercicio en curso: encabezado con cronómetro, animación,
/// series/reps/descanso, instrucciones, equipo y botón "Completado".
class ActiveExerciseView extends StatelessWidget {
  const ActiveExerciseView({
    super.key,
    required this.exercise,
    required this.index,
    required this.total,
    required this.workoutSeconds,
    required this.onCancel,
    required this.onComplete,
  });

  final Exercise exercise;
  final int index;
  final int total;
  final int workoutSeconds;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _purple400 = Color(0xFFA78BFA);

  bool get _isLast => index == total - 1;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 128 + bottomInset),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: _EnterTransition(
                      key: ValueKey<String>(exercise.id),
                      child: _buildContent(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildCta(bottomInset),
        ),
      ],
    );
  }

  // ── Encabezado fijo ───────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12 + topInset, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xE6000000),
        border: Border(bottom: BorderSide(color: AppColors.whiteA(0.08))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512 - 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Semantics(
                    button: true,
                    label: 'Salir del entrenamiento',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onCancel,
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.whiteA(0.08),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Ejercicio ${index + 1} de $total',
                        style: AppText.body(
                          size: 12,
                          color: AppColors.whiteA(0.45),
                          height: 1.333,
                        ),
                      ),
                      Text(
                        formatWorkoutTime(workoutSeconds),
                        style: AppText.display(
                          size: 14,
                          weight: FontWeight.w700,
                          color: _cyan400,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedProgressBar(
                value: (index + 1) / total,
                height: 4,
                animateOnMount: false,
                duration: const Duration(milliseconds: 400),
                trackColor: AppColors.whiteA(0.08),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contenido ─────────────────────────────────────────────────────────────
  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildDemoCard(context),
        const SizedBox(height: 20),
        _buildStatsRow(),
        const SizedBox(height: 20),
        _buildInstructions(),
        if (exercise.equipment.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _buildEquipment(),
        ],
      ],
    );
  }

  Widget _buildDemoCard(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanA(0.14)),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.08),
              centerX: 0.5,
              centerY: 0.5,
              radiusX: 0.6,
              radiusY: 0.5,
              fadeStop: 0.7,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ExerciseFigure(exerciseId: exercise.id, size: 160),
                const SizedBox(height: 12),
                Text(
                  exercise.name,
                  textAlign: TextAlign.center,
                  style: AppText.display(
                    size: 20,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cyanA(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    exercise.muscleGroup,
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: _cyan400,
                      height: 1.333,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Ver técnica',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showTechniqueSheet(context, exercise),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.whiteA(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.whiteA(0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: AppColors.whiteA(0.65),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ver técnica',
                              style: AppText.body(
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.whiteA(0.65),
                                height: 1.333,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.monitor_heart_outlined,
            label: 'Series',
            value: '${exercise.sets}',
            color: const Color(0xFF06B6D4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            label: 'Reps',
            value: exercise.reps,
            color: const Color(0xFF14B8A6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.timer_outlined,
            label: 'Descanso',
            value: '${exercise.rest}s',
            color: _purple400,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: _cyan400,
              ),
              const SizedBox(width: 8),
              Text(
                'Instrucciones',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.whiteA(0.70),
                  height: 1.43,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < exercise.instructions.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyanA(0.18),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.cyan,
                        height: 1.333,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.instructions[i],
                    style: AppText.body(
                      size: 14,
                      color: AppColors.whiteA(0.70),
                      height: 1.625,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipment() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String item in exercise.equipment)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.whiteA(0.07),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.whiteA(0.10)),
            ),
            child: Text(
              item,
              style: AppText.body(
                size: 12,
                color: AppColors.whiteA(0.55),
                height: 1.333,
              ),
            ),
          ),
      ],
    );
  }

  // ── Botón inferior ────────────────────────────────────────────────────────
  Widget _buildCta(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
          stops: <double>[0.0, 0.6, 1.0],
        ),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: _CtaButton(isLast: _isLast, onTap: onComplete),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.display(
              size: 20,
              weight: FontWeight.w700,
              color: color,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.40),
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  const _CtaButton({required this.isLast, required this.onTap});

  final bool isLast;
  final VoidCallback onTap;

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressing(true),
      onTapUp: (_) => _setPressing(false),
      onTapCancel: () => _setPressing(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: <Color>[AppColors.cyan, AppColors.teal],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.cyanA(0.30),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.isLast ? 'Finalizar Entrenamiento' : 'Completado',
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.isLast
                    ? Icons.check_rounded
                    : Icons.chevron_right_rounded,
                size: 22,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada del ejercicio: aparece desde la derecha (x: 30 -> 0) con fundido.
class _EnterTransition extends StatelessWidget {
  const _EnterTransition({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      builder: (BuildContext context, double v, Widget? c) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(30 * (1 - v), 0), child: c),
        );
      },
      child: child,
    );
  }
}