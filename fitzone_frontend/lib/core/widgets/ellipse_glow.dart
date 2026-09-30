import 'package:flutter/material.dart';

/// Gradiente radial elíptico (equivale a `radial-gradient(ellipse ...)` de CSS).
/// Centro y radios se expresan como fracción del ancho/alto del contenedor.
/// Úsalo dentro de un Stack, envuelto en `Positioned.fill`.
class EllipseGlow extends StatelessWidget {
  const EllipseGlow({
    super.key,
    required this.color,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.radiusX = 0.5,
    this.radiusY = 0.5,
    this.fadeStop = 0.6,
  });

  final Color color;
  final double centerX;
  final double centerY;
  final double radiusX;
  final double radiusY;

  /// Punto (0 a 1) del radio donde el color ya es totalmente transparente.
  final double fadeStop;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _EllipseGlowPainter(
            color: color,
            centerX: centerX,
            centerY: centerY,
            radiusX: radiusX,
            radiusY: radiusY,
            fadeStop: fadeStop,
          ),
        ),
      ),
    );
  }
}

class _EllipseGlowPainter extends CustomPainter {
  _EllipseGlowPainter({
    required this.color,
    required this.centerX,
    required this.centerY,
    required this.radiusX,
    required this.radiusY,
    required this.fadeStop,
  });

  final Color color;
  final double centerX;
  final double centerY;
  final double radiusX;
  final double radiusY;
  final double fadeStop;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = centerX * size.width;
    final double cy = centerY * size.height;
    final double rx = radiusX * size.width;
    final double ry = radiusY * size.height;
    if (rx <= 0 || ry <= 0) return;

    final Shader shader = RadialGradient(
      colors: <Color>[color, color.withAlpha(0)],
      stops: <double>[0.0, fadeStop],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));

    // Se dibuja un círculo unitario y se escala para volverlo elipse.
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(rx, ry);
    canvas.drawRect(
      Rect.fromLTRB(
        -cx / rx,
        -cy / ry,
        (size.width - cx) / rx,
        (size.height - cy) / ry,
      ),
      Paint()..shader = shader,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EllipseGlowPainter old) {
    return old.color != color ||
        old.centerX != centerX ||
        old.centerY != centerY ||
        old.radiusX != radiusX ||
        old.radiusY != radiusY ||
        old.fadeStop != fadeStop;
  }
}