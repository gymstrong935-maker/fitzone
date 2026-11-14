import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/shimmer_top_bar.dart';

const Cubic _spring = Cubic(0.22, 1, 0.36, 1);
const double _exitAt = 2.9;
const double _totalAt = 3.45;

double _seg(double t, double start, double dur) =>
    ((t - start) / dur).clamp(0.0, 1.0).toDouble();

Color _a(Color c, double opacity) =>
    c.withAlpha((255 * opacity).round().clamp(0, 255));

/// Animación de entrada de la app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onExit, required this.onComplete});

  /// Empieza a desvanecerse (ya se puede mostrar la primera pantalla debajo).
  final VoidCallback onExit;

  /// Terminó por completo.
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _exited = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration elapsed) {
      final double s = elapsed.inMicroseconds / 1000000.0;
      _time.value = s;
      if (!_exited && s >= _exitAt) {
        _exited = true;
        widget.onExit();
      }
      if (!_completed && s >= _totalAt) {
        _completed = true;
        _ticker.stop();
        widget.onComplete();
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ValueListenableBuilder<double>(
        valueListenable: _time,
        builder: (BuildContext context, double t, Widget? _) {
          final double fadeIn = Curves.easeOut.transform(_seg(t, 0.04, 0.4));
          final double fadeOut =
              const Cubic(0.4, 0, 1, 1).transform(_seg(t, _exitAt, 0.55));
          final double content = (fadeIn * (1 - fadeOut)).clamp(0.0, 1.0).toDouble();

          return IgnorePointer(
            ignoring: fadeOut > 0.5,
            child: Opacity(
              opacity: (1 - fadeOut).clamp(0.0, 1.0).toDouble(),
              child: ColoredBox(
                color: const Color(0xFF0A0A0A),
                child: Opacity(opacity: content, child: _Scene(t: t)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final double breathe = t < 1.8 ? 0.6 : 0.8 + 0.2 * math.sin((t - 1.8) * 2 * math.pi / 3);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(painter: _GlowPainter(breathe)),
        const Positioned(top: 0, left: 0, right: 0, child: ShimmerTopBar()),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Emblem(t: t),
              const SizedBox(height: 34),
              _Letters(t: t),
              const SizedBox(height: 14),
              _Tagline(t: t),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.46),
      width: size.width * 1.15,
      height: size.height * 0.75,
    );
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          _a(AppColors.cyan, 0.22 * opacity),
          _a(AppColors.teal, 0.05 * opacity),
          const Color(0x00000000),
        ],
        stops: const <double>[0, 0.6, 1],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.opacity != opacity;
}

// ═══════════════════════════════════════════════════════════════════════════
// Emblema: órbita, anillos, halo e ícono
// ═══════════════════════════════════════════════════════════════════════════

double _iconScale(double p) {
  double seg(double a, double b, double from, double to) =>
      from + (to - from) * Curves.easeOut.transform(((p - a) / (b - a)).clamp(0.0, 1.0));

  if (p < 0.5) return seg(0, 0.5, 0, 1.14);
  if (p < 0.7) return seg(0.5, 0.7, 1.14, 0.95);
  if (p < 0.85) return seg(0.7, 0.85, 0.95, 1.04);
  return seg(0.85, 1, 1.04, 1);
}

class _Emblem extends StatelessWidget {
  const _Emblem({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final double p = _seg(t, 0.2, 0.72);
    final double scale = _iconScale(p);
    final double opacity = (p / 0.5).clamp(0.0, 1.0).toDouble();
    final double bob = t < 2.0
        ? 1.0
        : 1 + 0.02 * (0.5 - 0.5 * math.cos((t - 2.0) * 2 * math.pi / 2.8));
    final double glow = t < 2.0 ? 0.6 : 0.8 + 0.2 * math.sin((t - 2.0) * 2 * math.pi / 2.8);

    Widget ring(int i) {
      final double start = 0.9 + i * 1.1;
      if (t < start) return const SizedBox.shrink();
      final double local = (((t - start) % 2.4) / 2.4);
      final double e = Curves.easeOut.transform(local);
      return Opacity(
        opacity: (0.65 * (1 - e)).clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(
          scale: 0.55 + 2.65 * e,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _a(AppColors.cyan, 0.5)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: -31,
            top: -31,
            width: 158,
            height: 158,
            child: CustomPaint(painter: _OrbitPainter(t)),
          ),
          ring(0),
          ring(1),
          Opacity(
            opacity: opacity,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: _a(AppColors.cyan, 0.18 * glow), blurRadius: 60),
                  BoxShadow(color: _a(AppColors.teal, 0.08 * glow), blurRadius: 100),
                ],
              ),
            ),
          ),
          Transform.scale(
            scale: scale * bob,
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(size: const Size(96, 96), painter: _IconPainter(t)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double op = 0.14 * _seg(t, 0.5, 0.6);
    if (op <= 0) return;

    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - 0.5;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _a(AppColors.cyan, op);

    final double rot = t * (2 * math.pi / 12);
    const int dashes = 56;
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        rot + i * 2 * math.pi / dashes,
        2 * math.pi / dashes * 0.5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.t != t;
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.t);

  final double t;

  RRect _rr(double l, double top, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(l, top, w, h), Radius.circular(r));

  Shader _h(double x1, double x2, List<Color> colors, [List<double>? stops]) =>
      ui.Gradient.linear(Offset(x1, 48), Offset(x2, 48), colors, stops);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 96);

    const Color cyan = AppColors.cyan;
    const Color cyanL = Color(0xFF22D3EE);
    const Color teal = AppColors.teal;
    const Color tealL = Color(0xFF2DD4BF);

    // Disco de fondo
    canvas.drawCircle(
      const Offset(48, 48),
      46,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(38, 36),
          60,
          <Color>[_a(cyan, 0.22), const Color(0xE60A0A0A)],
        ),
    );

    // Aro que se dibuja
    final double ring = const Cubic(0.4, 0, 0.2, 1).transform(_seg(t, 0.4, 0.85));
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(48, 48), radius: 46),
      0,
      2 * math.pi * ring,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(96, 96),
          <Color>[cyan, cyanL, teal],
          const <double>[0, 0.5, 1],
        ),
    );

    // Pesas que entran desde los lados
    final double plates = _spring.transform(_seg(t, 0.65, 0.5));
    if (plates > 0) {
      for (final int side in <int>[-1, 1]) {
        canvas.saveLayer(
          const Rect.fromLTWH(-40, 0, 176, 96),
          Paint()..color = Color.fromRGBO(255, 255, 255, plates),
        );
        canvas.translate(side * 22.0 * (1 - plates), 0);
        if (side < 0) {
          canvas.drawRRect(_rr(3, 28, 9, 40, 4), Paint()..shader = _h(3, 12, <Color>[cyan, cyanL]));
          canvas.drawRRect(_rr(12, 34, 6, 28, 2), Paint()..shader = _h(12, 18, <Color>[cyanL, cyan]));
        } else {
          canvas.drawRRect(_rr(78, 34, 6, 28, 2), Paint()..shader = _h(78, 84, <Color>[teal, tealL]));
          canvas.drawRRect(_rr(84, 28, 9, 40, 4), Paint()..shader = _h(84, 96, <Color>[teal, tealL]));
        }
        canvas.restore();
      }
    }

    // Barra que se estira
    final double bar = _spring.transform(_seg(t, 0.85, 0.45));
    if (bar > 0) {
      canvas.saveLayer(
        const Rect.fromLTWH(0, 0, 96, 96),
        Paint()..color = Color.fromRGBO(255, 255, 255, bar.clamp(0.0, 1.0)),
      );
      canvas.translate(48, 0);
      canvas.scale(bar.clamp(0.001, 1.0), 1);
      canvas.translate(-48, 0);
      canvas.drawRRect(
        _rr(18, 41, 60, 14, 5),
        Paint()..shader = _h(18, 78, <Color>[cyan, cyanL, teal], const <double>[0, 0.5, 1]),
      );
      canvas.restore();
    }

    // Rayo que se traza
    final double bolt = Curves.easeOut.transform(_seg(t, 1.05, 0.65));
    if (bolt > 0) {
      final Path path = Path()
        ..moveTo(49, 18)
        ..lineTo(44, 44)
        ..lineTo(52, 44)
        ..lineTo(47, 76);
      final ui.PathMetric metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * bolt),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = ui.Gradient.linear(
            const Offset(48, 18),
            const Offset(48, 76),
            <Color>[_a(Colors.white, 0.97), _a(cyanL, 0.9), _a(cyan, 0.55)],
            const <double>[0, 0.45, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════
// Letras y eslogan
// ═══════════════════════════════════════════════════════════════════════════

class _Letters extends StatelessWidget {
  const _Letters({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    const String word = 'FitZone';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < word.length; i++)
          _Letter(char: word[i], accent: i >= 3, t: t, index: i),
      ],
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.char,
    required this.accent,
    required this.t,
    required this.index,
  });

  final String char;
  final bool accent;
  final double t;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double p = _spring.transform(_seg(t, 0.75 + index * 0.065, 0.52));
    final double blur = 8 * (1 - p);

    TextStyle style = AppText.display(
      size: 44.8,
      weight: FontWeight.w700,
      letterSpacing: -1.12,
      height: 1,
      color: accent ? AppColors.cyan : Colors.white,
    );
    if (accent) {
      style = style.copyWith(
        shadows: <Shadow>[
          Shadow(color: _a(AppColors.cyan, 0.5), blurRadius: 22),
          Shadow(color: _a(AppColors.cyan, 0.18), blurRadius: 44),
        ],
      );
    }

    Widget text = Text(char, style: style);
    if (blur > 0.2) {
      text = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: text,
      );
    }

    return Opacity(
      opacity: p.clamp(0.0, 1.0).toDouble(),
      child: Transform.translate(offset: Offset(0, 20 * (1 - p)), child: text),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final double p = Curves.easeOut.transform(_seg(t, 1.6, 0.9));

    return Opacity(
      opacity: 0.38 * p,
      child: Text(
        'TU ZONA DE RENDIMIENTO',
        style: AppText.body(size: 10.7, letterSpacing: 2.6, color: Colors.white),
      ),
    );
  }
}