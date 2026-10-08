import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tarjeta "glass": fondo translúcido con desenfoque, borde y sombra exterior.
class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({super.key, required this.child});

  final Widget child;

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _OuterShadowPainter(_radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.whiteA(0.04),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: AppColors.whiteA(0.10)),
            ),
            child: Stack(
              children: <Widget>[
                // Línea de luz superior (equivale al inset shadow del diseño).
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  height: 1,
                  child: ColoredBox(color: AppColors.whiteA(0.06)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sombra que solo se dibuja FUERA de la tarjeta (como en CSS), para que no
/// oscurezca el interior translúcido.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect card = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final Path outside = Path.combine(
      PathOperation.difference,
      Path()
        ..addRect(
          Rect.fromLTWH(-300, -300, size.width + 600, size.height + 600),
        ),
      Path()..addRRect(card),
    );

    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      card.shift(const Offset(0, 24)),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OuterShadowPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}