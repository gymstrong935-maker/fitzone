import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';

/// Figura animada de un ejercicio (lienzo de 130 x 160 unidades escalado al
/// tamaño pedido).
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({super.key, required this.exerciseId, this.size = 160});

  final String exerciseId;
  final double size;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration elapsed) {
      _seconds.value = elapsed.inMicroseconds / 1000000.0;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _FigurePainter(
          exerciseId: widget.exerciseId,
          seconds: _seconds,
        ),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({required this.exerciseId, required this.seconds})
      : super(repaint: seconds);

  final String exerciseId;
  final ValueListenable<double> seconds;

  @override
  void paint(Canvas canvas, Size size) {
    // Igual que el SVG: lo que sale del lienzo se recorta.
    canvas.clipRect(Offset.zero & size);

    // viewBox 130 x 160, centrado y ajustado a la altura.
    final double scale = size.height / 160;
    canvas.translate((size.width - 130 * scale) / 2, 0);
    canvas.scale(scale);

    final double t = seconds.value;
    switch (exerciseId) {
      case 'ex-1':
        _drawBench(canvas, t);
      case 'ex-2':
        _drawSquat(canvas, t);
      case 'ex-3':
        _drawPress(canvas, t);
      case 'ex-4':
        _drawDeadlift(canvas, t);
      case 'ex-5':
        _drawPullUp(canvas, t);
      case 'ex-6':
        _drawCurl(canvas, t);
      default:
        _drawGeneric(canvas, t);
    }

    // Sombra del suelo.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(65, 155), width: 70, height: 8),
      Paint()..color = const Color.fromRGBO(6, 182, 212, 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _FigurePainter oldDelegate) {
    return oldDelegate.exerciseId != exerciseId;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Utilidades de animación
// ═══════════════════════════════════════════════════════════════════════════

/// Fase 0..1 de un ciclo de [period] segundos.
double _phase(double seconds, double period) => (seconds / period) % 1.0;

/// Onda de ida y vuelta: sube de 0 a 1 en [0, r], se queda en 1 hasta 1 - r y
/// vuelve a 0. Equivale a los keyframes "0%,100% a; r%,(100-r)% b" de CSS.
double _wave(double t, double r, [Curve curve = Curves.easeInOut]) {
  if (t < r) return curve.transform(t / r);
  if (t < 1 - r) return 1;
  return curve.transform((1 - t) / r);
}

// ═══════════════════════════════════════════════════════════════════════════
// Pinceles y formas
// ═══════════════════════════════════════════════════════════════════════════

Paint _fill(Color color) => Paint()..color = color;

Paint _stroke(double width, [Color? color]) {
  return Paint()
    ..color = color ?? AppColors.whiteA(0.28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}

void _line(Canvas c, double x1, double y1, double x2, double y2, double w) {
  c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(w));
}

void _rrect(Canvas c, double x, double y, double w, double h, double r, Paint p) {
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
    p,
  );
}

/// Barra con degradado horizontal cian -> turquesa.
Paint _barPaint(double x, double y, double w, double h, [double opacity = 1]) {
  final int a = (opacity * 255).round();
  return Paint()
    ..shader = LinearGradient(
      colors: <Color>[AppColors.cyan.withAlpha(a), AppColors.teal.withAlpha(a)],
    ).createShader(Rect.fromLTWH(x, y, w, h));
}

void _plate(
  Canvas c,
  double x,
  double y,
  double w,
  double h,
  double r,
  Color color,
  double opacity,
) {
  _rrect(c, x, y, w, h, r, _fill(color.withAlpha((opacity * 255).round())));
}

void _head(Canvas c, double cx, double cy, double r) {
  c.drawCircle(Offset(cx, cy), r, _fill(AppColors.whiteA(0.14)));
  c.drawCircle(
    Offset(cx, cy),
    r,
    Paint()
      ..color = AppColors.whiteA(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
}

void _torso(Canvas c, double x, double y, double w, double h, double r) {
  _rrect(c, x, y, w, h, r, _fill(AppColors.whiteA(0.10)));
  _rrect(
    c,
    x,
    y,
    w,
    h,
    r,
    Paint()
      ..color = AppColors.whiteA(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
}

const Color _cyan = Color(0xFF06B6D4);
const Color _teal = Color(0xFF14B8A6);

// ═══════════════════════════════════════════════════════════════════════════
// Press de banca (ex-1)
// ═══════════════════════════════════════════════════════════════════════════

void _drawBench(Canvas canvas, double t) {
  // Banco.
  _rrect(canvas, 15, 115, 100, 8, 4, _fill(AppColors.whiteA(0.10)));
  _rrect(canvas, 30, 105, 70, 12, 4, _fill(AppColors.whiteA(0.07)));
  _line(canvas, 28, 123, 22, 140, 4);
  _line(canvas, 102, 123, 108, 140, 4);

  // Persona acostada (flota suavemente).
  canvas.save();
  canvas.translate(0, -5 * _wave(_phase(t, 3.5), 0.5));

  _head(canvas, 112, 100, 10);
  _torso(canvas, 36, 96, 68, 18, 7);

  // Brazos + barra suben y bajan.
  canvas.save();
  canvas.translate(0, -28 * _wave(_phase(t, 2.4), 0.4));
  _line(canvas, 42, 98, 28, 72, 5);
  _line(canvas, 88, 98, 100, 72, 5);
  _rrect(canvas, 10, 67, 110, 6, 3, _barPaint(10, 67, 110, 6));
  _plate(canvas, 6, 60, 7, 20, 2.5, _cyan, 0.85);
  _plate(canvas, 117, 60, 7, 20, 2.5, _teal, 0.85);
  canvas.restore();

  // Piernas.
  _line(canvas, 44, 112, 28, 130, 6);
  _line(canvas, 68, 112, 75, 132, 6);
  canvas.restore();
}

// ═══════════════════════════════════════════════════════════════════════════
// Sentadilla (ex-2)
// ═══════════════════════════════════════════════════════════════════════════

void _drawSquat(Canvas canvas, double t) {
  // Rack.
  _rrect(canvas, 10, 28, 110, 5, 2.5, _barPaint(10, 28, 110, 5, 0.4));
  _rrect(canvas, 8, 22, 5, 50, 2, _fill(AppColors.whiteA(0.15)));
  _rrect(canvas, 117, 22, 5, 50, 2, _fill(AppColors.whiteA(0.15)));

  // Toda la persona baja y sube.
  canvas.save();
  canvas.translate(0, 18 * _wave(_phase(t, 2.6), 0.5));

  _head(canvas, 65, 22, 10);
  _torso(canvas, 48, 34, 34, 38, 8);
  _rrect(canvas, 20, 37, 90, 5, 2.5, _barPaint(20, 37, 90, 5));
  _plate(canvas, 16, 32, 7, 16, 2.5, _cyan, 0.85);
  _plate(canvas, 107, 32, 7, 16, 2.5, _teal, 0.85);
  _line(canvas, 52, 42, 30, 43, 5);
  _line(canvas, 78, 42, 100, 43, 5);
  _line(canvas, 58, 70, 44, 105, 7);
  _line(canvas, 44, 105, 36, 140, 6);
  _line(canvas, 72, 70, 86, 105, 7);
  _line(canvas, 86, 105, 94, 140, 6);
  canvas.restore();
}

// ═══════════════════════════════════════════════════════════════════════════
// Press militar (ex-3)
// ═══════════════════════════════════════════════════════════════════════════

void _drawPress(Canvas canvas, double t) {
  canvas.save();
  canvas.translate(0, -5 * _wave(_phase(t, 3.2), 0.5));

  _head(canvas, 65, 28, 12);
  _torso(canvas, 48, 42, 34, 44, 9);
  _line(canvas, 58, 84, 50, 122, 7);
  _line(canvas, 50, 122, 44, 150, 6);
  _line(canvas, 72, 84, 80, 122, 7);
  _line(canvas, 80, 122, 86, 150, 6);

  // Brazos + barra empujan hacia arriba.
  canvas.save();
  canvas.translate(0, -24 * _wave(_phase(t, 2.4), 0.45));
  _line(canvas, 50, 55, 22, 40, 5);
  _line(canvas, 80, 55, 108, 40, 5);
  _rrect(canvas, 12, 33, 106, 6, 3, _barPaint(12, 33, 106, 6));
  _plate(canvas, 8, 26, 7, 20, 2.5, _cyan, 0.85);
  _plate(canvas, 115, 26, 7, 20, 2.5, _teal, 0.85);
  canvas.restore();

  canvas.restore();
}

// ═══════════════════════════════════════════════════════════════════════════
// Peso muerto (ex-4)
// ═══════════════════════════════════════════════════════════════════════════

void _drawDeadlift(Canvas canvas, double t) {
  // Barra en el suelo.
  _rrect(canvas, 10, 135, 110, 6, 3, _barPaint(10, 135, 110, 6));
  _plate(canvas, 6, 122, 10, 20, 3, _cyan, 0.85);
  _plate(canvas, 114, 122, 10, 20, 3, _teal, 0.85);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(65, 148), width: 80, height: 10),
    _fill(const Color.fromRGBO(6, 182, 212, 0.07)),
  );

  canvas.save();
  canvas.translate(0, -5 * _wave(_phase(t, 3.5), 0.5));

  _head(canvas, 65, 22, 11);

  // Torso y brazos giran desde la cadera (-28° con un pequeño descenso).
  final double p = _wave(_phase(t, 2.8), 0.5);
  canvas.save();
  canvas.translate(65, 112);
  canvas.translate(0, 6 * p);
  canvas.rotate(-28 * p * 3.141592653589793 / 180);
  canvas.translate(-65, -112);
  _torso(canvas, 49, 35, 32, 48, 9);
  _line(canvas, 50, 50, 28, 80, 5);
  _line(canvas, 28, 80, 22, 112, 4.5);
  _line(canvas, 80, 50, 102, 80, 5);
  _line(canvas, 102, 80, 108, 112, 4.5);
  canvas.restore();

  // Piernas.
  _line(canvas, 58, 82, 46, 118, 7);
  _line(canvas, 46, 118, 40, 138, 6);
  _line(canvas, 72, 82, 84, 118, 7);
  _line(canvas, 84, 118, 90, 138, 6);
  canvas.restore();
}

// ═══════════════════════════════════════════════════════════════════════════
// Dominadas (ex-5)
// ═══════════════════════════════════════════════════════════════════════════

void _drawPullUp(Canvas canvas, double t) {
  // Barra y soportes.
  _rrect(canvas, 8, 18, 114, 7, 3.5, _fill(AppColors.whiteA(0.25)));
  _rrect(
    canvas,
    8,
    18,
    114,
    7,
    3.5,
    Paint()
      ..color = AppColors.whiteA(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  _rrect(canvas, 12, 6, 5, 16, 2, _fill(AppColors.whiteA(0.18)));
  _rrect(canvas, 113, 6, 5, 16, 2, _fill(AppColors.whiteA(0.18)));

  // La persona sube y baja.
  canvas.save();
  canvas.translate(0, -22 * _wave(_phase(t, 2.6), 0.45));
  _line(canvas, 48, 25, 42, 55, 6);
  _line(canvas, 82, 25, 88, 55, 6);
  _head(canvas, 65, 66, 11);
  _torso(canvas, 49, 79, 32, 42, 9);
  _line(canvas, 58, 119, 52, 148, 7);
  _line(canvas, 52, 148, 46, 170, 6);
  _line(canvas, 72, 119, 78, 148, 7);
  _line(canvas, 78, 148, 84, 170, 6);
  canvas.restore();
}

// ═══════════════════════════════════════════════════════════════════════════
// Curl de bíceps (ex-6)
// ═══════════════════════════════════════════════════════════════════════════

void _drawCurl(Canvas canvas, double t) {
  canvas.save();
  canvas.translate(0, -5 * _wave(_phase(t, 3.0), 0.5));

  _head(canvas, 65, 22, 12);
  _torso(canvas, 48, 36, 34, 48, 9);

  // Brazo izquierdo (quieto).
  _line(canvas, 50, 48, 28, 72, 6);
  _line(canvas, 28, 72, 22, 100, 5);

  // Brazo derecho: parte alta quieta y antebrazo que hace el curl.
  _line(canvas, 80, 48, 104, 72, 6);
  final double angle =
      115 * _wave(_phase(t, 2.4), 0.4, Curves.fastOutSlowIn) * 3.141592653589793 / 180;
  canvas.save();
  canvas.translate(104, 72);
  canvas.rotate(angle);
  _line(canvas, 0, 0, 0, 30, 5);
  _rrect(canvas, -13, 27, 26, 6, 3, _barPaint(-13, 27, 26, 6));
  _plate(canvas, -19, 24, 7, 12, 2.5, _cyan, 0.9);
  _plate(canvas, 12, 24, 7, 12, 2.5, _teal, 0.9);
  canvas.restore();

  // Piernas.
  _line(canvas, 58, 82, 50, 118, 7);
  _line(canvas, 50, 118, 44, 148, 6);
  _line(canvas, 72, 82, 80, 118, 7);
  _line(canvas, 80, 118, 86, 148, 6);
  canvas.restore();
}

// ═══════════════════════════════════════════════════════════════════════════
// Figura genérica (ejercicio sin dibujo propio)
// ═══════════════════════════════════════════════════════════════════════════

void _drawGeneric(Canvas canvas, double t) {
  canvas.save();
  canvas.translate(0, -5 * _wave(_phase(t, 3.0), 0.5));
  _head(canvas, 65, 22, 12);
  _torso(canvas, 48, 36, 34, 48, 9);
  _line(canvas, 58, 82, 50, 118, 7);
  _line(canvas, 72, 82, 80, 118, 7);
  canvas.restore();
}