import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/exercise.dart';

/// Pantalla de descanso: anillo con cuenta regresiva y el siguiente ejercicio.
class RestTimerView extends StatelessWidget {
  const RestTimerView({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.nextExercise,
    required this.onSkip,
  });

  final int secondsLeft;
  final int totalSeconds;
  final Exercise nextExercise;
  final VoidCallback onSkip;

  static const Color _cyan400 = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    final double fraction =
        totalSeconds <= 0 ? 0 : (secondsLeft / totalSeconds).clamp(0.0, 1.0).toDouble();

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (BuildContext context, double v, Widget? child) {
                return Opacity(
                  opacity: v,
                  child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Descansa',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 14,
                      color: AppColors.whiteA(0.50),
                      height: 1.43,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prepárate para el siguiente ejercicio',
                    textAlign: TextAlign.center,
                    style: AppText.display(
                      size: 24,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.333,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Anillo ──
                  Center(
                    child: SizedBox(
                      width: 176,
                      height: 176,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: fraction),
                            duration: const Duration(milliseconds: 500),
                            builder: (
                              BuildContext context,
                              double value,
                              Widget? _,
                            ) {
                              return CustomPaint(
                                size: const Size(176, 176),
                                painter: _RestRingPainter(value),
                              );
                            },
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '$secondsLeft',
                                style: AppText.display(
                                  size: 48,
                                  weight: FontWeight.w700,
                                  color: _cyan400,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'segundos',
                                style: AppText.body(
                                  size: 12,
                                  color: AppColors.whiteA(0.45),
                                  height: 1.333,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Saltar descanso ──
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSkip,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.whiteA(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.whiteA(0.15)),
                      ),
                      child: Text(
                        'Saltar Descanso',
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.43,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Siguiente ejercicio ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cyanA(0.07),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cyanA(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Siguiente ejercicio',
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.45),
                            height: 1.333,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextExercise.name,
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.43,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nextExercise.muscleGroup} · ${nextExercise.sets} series × ${nextExercise.reps} reps',
                          style: AppText.body(
                            size: 12,
                            color: _cyan400,
                            height: 1.333,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestRingPainter extends CustomPainter {
  const _RestRingPainter(this.fraction);

  final double fraction;

  // El diseño usa un lienzo de 192 con radio 80 y trazo 8; aquí el anillo
  // mide 176, así que todo se escala por 176 / 192.
  static const double _scale = 176 / 192;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = 80 * _scale;
    final double stroke = 8 * _scale;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.whiteA(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    final double sweep = 2 * math.pi * fraction.clamp(0.0, 1.0).toDouble();
    if (sweep <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[AppColors.cyan, AppColors.teal],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RestRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}