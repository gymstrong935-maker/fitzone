import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ellipse_glow.dart';

/// Fondo de la pantalla de auth: degradado, brillos elípticos y cuadrícula.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.36, -1),
                end: Alignment(0.36, 1),
                colors: <Color>[
                  Color(0xFF06111C),
                  Color(0xFF071E2A),
                  Color(0xFF050D13),
                  Color(0xFF03080D),
                ],
                stops: <double>[0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: EllipseGlow(
            color: AppColors.cyanA(0.16),
            centerX: 0.25,
            centerY: 0.15,
            radiusX: 0.75,
            radiusY: 0.55,
            fadeStop: 0.6,
          ),
        ),
        Positioned.fill(
          child: EllipseGlow(
            color: AppColors.tealA(0.12),
            centerX: 0.80,
            centerY: 0.75,
            radiusX: 0.55,
            radiusY: 0.45,
            fadeStop: 0.55,
          ),
        ),
        const Positioned.fill(
          child: EllipseGlow(
            color: Color.fromRGBO(34, 211, 238, 0.06),
            centerX: 0.60,
            centerY: 0.35,
            radiusX: 0.40,
            radiusY: 0.35,
            fadeStop: 0.5,
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ),
      ],
    );
  }
}

/// Cuadrícula sutil de 44 px.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromRGBO(6, 182, 212, 0.035)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}