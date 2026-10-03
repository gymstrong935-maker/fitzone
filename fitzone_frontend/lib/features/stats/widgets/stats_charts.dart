import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/stats_data.dart';
import 'chart_common.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Curva suave (equivale al "monotone" de Recharts / d3.curveMonotoneX)
// ═══════════════════════════════════════════════════════════════════════════

Path monotonePath(List<Offset> p) {
  final Path path = Path()..moveTo(p.first.dx, p.first.dy);
  final int n = p.length;
  if (n == 1) return path;
  if (n == 2) {
    path.lineTo(p[1].dx, p[1].dy);
    return path;
  }

  double sign(double x) => x < 0 ? -1 : 1;

  // Tangente de cada punto (algoritmo de d3).
  final List<double> m = List<double>.filled(n, 0);
  for (int i = 1; i < n - 1; i++) {
    final double h0 = p[i].dx - p[i - 1].dx;
    final double h1 = p[i + 1].dx - p[i].dx;
    final double s0 = (p[i].dy - p[i - 1].dy) / h0;
    final double s1 = (p[i + 1].dy - p[i].dy) / h1;
    final double avg = (s0 * h1 + s1 * h0) / (h0 + h1);
    final double t = (sign(s0) + sign(s1)) *
        math.min(s0.abs(), math.min(s1.abs(), 0.5 * avg.abs()));
    m[i] = t.isNaN ? 0 : t;
  }
  final double hFirst = p[1].dx - p[0].dx;
  m[0] = (3 * (p[1].dy - p[0].dy) / hFirst - m[1]) / 2;
  final double hLast = p[n - 1].dx - p[n - 2].dx;
  m[n - 1] = (3 * (p[n - 1].dy - p[n - 2].dy) / hLast - m[n - 2]) / 2;

  for (int i = 0; i < n - 1; i++) {
    final double dx = (p[i + 1].dx - p[i].dx) / 3;
    path.cubicTo(
      p[i].dx + dx,
      p[i].dy + dx * m[i],
      p[i + 1].dx - dx,
      p[i + 1].dy - dx * m[i + 1],
      p[i + 1].dx,
      p[i + 1].dy,
    );
  }
  return path;
}

// ═══════════════════════════════════════════════════════════════════════════
// Gráfica de área: peso corporal
// ═══════════════════════════════════════════════════════════════════════════

class WeightAreaChart extends StatelessWidget {
  const WeightAreaChart({super.key, required this.data});

  final List<WeightPoint> data;

  static const double _yMin = 72;
  static const double _yMax = 76;

  static List<Offset> _points(List<WeightPoint> data, Size size) {
    final Rect r = ChartPlot(size).rect;
    final int n = data.length;
    return <Offset>[
      for (int i = 0; i < n; i++)
        Offset(
          r.left + (n == 1 ? 0 : i / (n - 1) * r.width),
          r.bottom - (data[i].kg - _yMin) / (_yMax - _yMin) * r.height,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveChart(
      height: 180,
      indexAt: (Offset position, Size size) {
        final Rect r = ChartPlot(size).rect;
        if (!r.contains(position)) return null;
        final int n = data.length;
        final double t = (position.dx - r.left) / r.width;
        return (t * (n - 1)).round().clamp(0, n - 1);
      },
      anchorFor: (int index, Size size) => _points(data, size)[index],
      painterBuilder: (int? active) => _WeightPainter(data, active),
      tooltipBuilder: (int index) => ChartTooltip(
        label: data[index].week,
        name: 'Peso',
        value: '${formatStat(data[index].kg)} kg',
      ),
    );
  }
}

class _WeightPainter extends CustomPainter {
  const _WeightPainter(this.data, this.activeIndex);

  final List<WeightPoint> data;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final ChartPlot plot = ChartPlot(size);
    final Rect r = plot.rect;
    final List<Offset> pts = WeightAreaChart._points(data, size);

    paintChartAxes(
      canvas,
      plot,
      yTicks: const <double>[72, 73, 74, 75, 76],
      yMin: WeightAreaChart._yMin,
      yMax: WeightAreaChart._yMax,
      xLabels: <String>[for (final WeightPoint d in data) d.week],
      xCenters: <double>[for (final Offset o in pts) o.dx],
    );

    // Área con degradado vertical (cian 25 % -> transparente).
    final Path line = monotonePath(pts);
    final Path area = Path.from(line)
      ..lineTo(pts.last.dx, r.bottom)
      ..lineTo(pts.first.dx, r.bottom)
      ..close();
    final Rect bounds = area.getBounds();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.cyanA(0.25), AppColors.cyanA(0)],
        ).createShader(bounds),
    );

    // Línea.
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Línea vertical del cursor.
    final int? active = activeIndex;
    if (active != null) {
      canvas.drawLine(
        Offset(pts[active].dx, r.top),
        Offset(pts[active].dx, r.bottom),
        Paint()
          ..color = const Color(0xFFCCCCCC)
          ..strokeWidth = 1,
      );
    }

    // Puntos.
    final Paint dotPaint = Paint()..color = AppColors.cyan;
    for (int i = 0; i < pts.length; i++) {
      if (i == active) continue;
      canvas.drawCircle(pts[i], 4, dotPaint);
    }
    if (active != null) {
      canvas.drawCircle(pts[active], 6, dotPaint);
      canvas.drawCircle(
        pts[active],
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeightPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex || oldDelegate.data != data;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Gráfica de barras: minutos de entrenamiento
// ═══════════════════════════════════════════════════════════════════════════

class ActivityBarChart extends StatelessWidget {
  const ActivityBarChart({super.key, required this.data});

  final List<ActivityPoint> data;

  /// Paso del eje Y (múltiplo de 5) para que el máximo quepa en 4 divisiones.
  static int _step(List<ActivityPoint> data) {
    final int maxValue = data.fold<int>(0, (int m, ActivityPoint d) => math.max(m, d.minutes));
    return math.max(5, (maxValue / 4 / 5).ceil() * 5);
  }

  @override
  Widget build(BuildContext context) {
    final int step = _step(data);

    return InteractiveChart(
      height: 180,
      indexAt: (Offset position, Size size) {
        final Rect r = ChartPlot(size).rect;
        if (!r.contains(position)) return null;
        final double band = r.width / data.length;
        return ((position.dx - r.left) / band).floor().clamp(0, data.length - 1);
      },
      anchorFor: (int index, Size size) {
        final Rect r = ChartPlot(size).rect;
        final double band = r.width / data.length;
        final double h = data[index].minutes / (step * 4) * r.height;
        return Offset(r.left + band * (index + 0.5), r.bottom - h);
      },
      painterBuilder: (int? active) => _ActivityPainter(data, step, active),
      tooltipBuilder: (int index) => ChartTooltip(
        label: data[index].day,
        name: 'Duración',
        value: '${data[index].minutes} min',
      ),
    );
  }
}

class _ActivityPainter extends CustomPainter {
  const _ActivityPainter(this.data, this.step, this.activeIndex);

  final List<ActivityPoint> data;
  final int step;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final ChartPlot plot = ChartPlot(size);
    final Rect r = plot.rect;
    final int n = data.length;
    final double band = r.width / n;
    final double yMax = (step * 4).toDouble();

    paintChartAxes(
      canvas,
      plot,
      yTicks: <double>[for (int i = 0; i <= 4; i++) (i * step).toDouble()],
      yMin: 0,
      yMax: yMax,
      xLabels: <String>[for (final ActivityPoint d in data) d.day],
      xCenters: <double>[for (int i = 0; i < n; i++) r.left + band * (i + 0.5)],
    );

    // Franja del cursor (detrás de las barras).
    final int? active = activeIndex;
    if (active != null) {
      canvas.drawRect(
        Rect.fromLTWH(r.left + band * active, r.top, band, r.height),
        Paint()..color = const Color.fromRGBO(204, 204, 204, 0.15),
      );
    }

    // Barras: ancho = 80 % de la franja, máximo 32 px; esquinas superiores
    // redondeadas de 6 px y degradado cian -> turquesa.
    final double barWidth = math.min(band * 0.8, 32);
    for (int i = 0; i < n; i++) {
      final double height = data[i].minutes / yMax * r.height;
      if (height <= 0) continue;

      final Rect barRect = Rect.fromLTWH(
        r.left + band * i + (band - barWidth) / 2,
        r.bottom - height,
        barWidth,
        height,
      );

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.cyan, AppColors.teal],
          ).createShader(barRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.data != data ||
        oldDelegate.step != step;
  }
}