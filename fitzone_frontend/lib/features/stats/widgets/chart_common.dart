import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Área de dibujo de la gráfica (mismos márgenes que usa el diseño:
/// izquierda 36, derecha 4, arriba 4 y 30 de eje X abajo).
class ChartPlot {
  const ChartPlot(this.size);

  final Size size;

  static const double left = 36;
  static const double right = 4;
  static const double top = 4;
  static const double bottomAxis = 30;

  Rect get rect => Rect.fromLTRB(
        left,
        top,
        size.width - right,
        size.height - bottomAxis,
      );
}

TextStyle chartAxisStyle() =>
    AppText.body(size: 11, color: AppColors.whiteA(0.35));

String formatTick(double t) =>
    t == t.roundToDouble() ? t.toInt().toString() : t.toString();

/// Dibuja [text] de modo que el punto [at] quede en la posición [align] del
/// texto (p. ej. `Alignment.centerRight` = el borde derecho centrado en [at]).
void drawChartText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset at,
  Alignment align,
) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  painter.paint(
    canvas,
    Offset(
      at.dx - painter.width * (align.x + 1) / 2,
      at.dy - painter.height * (align.y + 1) / 2,
    ),
  );
}

/// Cuadrícula horizontal punteada (3 px / 3 px) + etiquetas de los dos ejes.
void paintChartAxes(
  Canvas canvas,
  ChartPlot plot, {
  required List<double> yTicks,
  required double yMin,
  required double yMax,
  required List<String> xLabels,
  required List<double> xCenters,
}) {
  final Rect r = plot.rect;
  final Paint gridPaint = Paint()
    ..color = AppColors.whiteA(0.06)
    ..strokeWidth = 1;
  final TextStyle style = chartAxisStyle();

  for (final double tick in yTicks) {
    final double y = r.bottom - (tick - yMin) / (yMax - yMin) * r.height;

    for (double x = r.left; x < r.right; x += 6) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 3, r.right), y),
        gridPaint,
      );
    }

    drawChartText(
      canvas,
      formatTick(tick),
      style,
      Offset(r.left - 8, y),
      Alignment.centerRight,
    );
  }

  for (int i = 0; i < xLabels.length; i++) {
    drawChartText(
      canvas,
      xLabels[i],
      style,
      Offset(xCenters[i], r.bottom + 8),
      Alignment.topCenter,
    );
  }
}

/// Cuadro de información que aparece al pasar el cursor o tocar un punto.
class ChartTooltip extends StatelessWidget {
  const ChartTooltip({
    super.key,
    required this.label,
    required this.name,
    required this.value,
    this.color = AppColors.cyan,
  });

  final String label;
  final String name;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.whiteA(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.7),
              height: 1.333,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$name : $value',
            softWrap: false,
            style: AppText.body(size: 12, color: color, height: 1.333),
          ),
        ],
      ),
    );
  }
}

class _TooltipLayoutDelegate extends SingleChildLayoutDelegate {
  const _TooltipLayoutDelegate(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // A la derecha del punto; si no cabe, a la izquierda.
    double x = anchor.dx + 12;
    if (x + childSize.width > size.width) {
      x = anchor.dx - 12 - childSize.width;
    }
    x = x.clamp(0.0, math.max(0.0, size.width - childSize.width)).toDouble();

    // Encima del punto; si no cabe, debajo.
    double y = anchor.dy - childSize.height - 10;
    if (y < 0) y = anchor.dy + 14;
    y = y.clamp(0.0, math.max(0.0, size.height - childSize.height)).toDouble();

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _TooltipLayoutDelegate oldDelegate) {
    return oldDelegate.anchor != anchor;
  }
}

/// Lienzo interactivo: detecta el cursor o el dedo, calcula qué punto/barra
/// está activo, redibuja la gráfica y muestra el cuadro de información.
class InteractiveChart extends StatefulWidget {
  const InteractiveChart({
    super.key,
    required this.height,
    required this.indexAt,
    required this.anchorFor,
    required this.painterBuilder,
    required this.tooltipBuilder,
  });

  final double height;

  /// Índice activo para una posición local (o `null` si está fuera del área).
  final int? Function(Offset position, Size size) indexAt;

  /// Punto (en coordenadas locales) donde se ancla el cuadro de información.
  final Offset Function(int index, Size size) anchorFor;

  final CustomPainter Function(int? activeIndex) painterBuilder;
  final Widget Function(int index) tooltipBuilder;

  @override
  State<InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  int? _index;

  void _update(Offset? position, Size size) {
    final int? next = position == null ? null : widget.indexAt(position, size);
    if (next != _index) setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, widget.height);
        final int? index = _index;

        return MouseRegion(
          onHover: (event) => _update(event.localPosition, size),          onExit: (_) => _update(null, size),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails d) => _update(d.localPosition, size),
            onHorizontalDragUpdate: (DragUpdateDetails d) =>
                _update(d.localPosition, size),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: <Widget>[
                  CustomPaint(
                    size: size,
                    painter: widget.painterBuilder(index),
                  ),
                  if (index != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomSingleChildLayout(
                          delegate: _TooltipLayoutDelegate(
                            widget.anchorFor(index, size),
                          ),
                          child: widget.tooltipBuilder(index),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}