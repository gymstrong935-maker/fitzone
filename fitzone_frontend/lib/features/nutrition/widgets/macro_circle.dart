import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Anillo de progreso de un macronutriente (80 px) con su etiqueta y meta.
class MacroCircle extends StatelessWidget {
  const MacroCircle({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  final String label;
  final int current;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fraction = goal <= 0 ? 0 : current / goal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size(80, 80),
                painter: _RingPainter(fraction: fraction, color: color),
              ),
              Text(
                '${current}g',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.60),
            height: 1.333,
          ),
        ),
        Text(
          '${goal}g meta',
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.40),
            height: 1.333,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  static const double _radius = 36;
  static const double _stroke = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    // Pista.
    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..color = AppColors.whiteA(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );

    // Progreso: empieza arriba y avanza en sentido horario.
    final double sweep = 2 * math.pi * fraction.clamp(0.0, 1.0).toDouble();
    if (sweep <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: _radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.color != color;
  }
}