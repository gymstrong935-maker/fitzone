import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'fz_label.dart';
import 'fz_number_field.dart' show formatNumber;

/// Slider con el estilo del diseño: pista de 16 px, relleno cian y botón
/// circular con borde cian. El valor se ajusta a múltiplos de [step].
class FzStepSlider extends StatefulWidget {
  const FzStepSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = 1,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final String? semanticLabel;

  @override
  State<FzStepSlider> createState() => _FzStepSliderState();
}

class _FzStepSliderState extends State<FzStepSlider> {
  static const double _thumb = 16;
  static const double _trackHeight = 16;
  static const double _boxHeight = 24;

  bool _hover = false;
  bool _dragging = false;

  /// Ajusta [raw] al múltiplo de `step` más cercano dentro de [min, max].
  double _snap(double raw) {
    final int n = ((raw - widget.min) / widget.step).round();
    final double v = widget.min + n * widget.step;
    return math.max(widget.min, math.min(widget.max, v));
  }

  void _set(double raw) {
    final double next = _snap(raw);
    if (next != widget.value) widget.onChanged(next);
  }

  void _updateFromDx(double dx, double width) {
    final double travel = width - _thumb;
    if (travel <= 0) return;
    final double t = ((dx - _thumb / 2) / travel).clamp(0.0, 1.0).toDouble();
    _set(widget.min + t * (widget.max - widget.min));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: formatNumber(widget.value),
      increasedValue: formatNumber(_snap(widget.value + widget.step)),
      decreasedValue: formatNumber(_snap(widget.value - widget.step)),
      onIncrease: () => _set(widget.value + widget.step),
      onDecrease: () => _set(widget.value - widget.step),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double travel = width - _thumb;
            final double range = widget.max - widget.min;
            final double t = range <= 0 ? 0 : (widget.value - widget.min) / range;
            final double thumbLeft = t.clamp(0.0, 1.0).toDouble() * travel;
            final bool ring = _hover || _dragging;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails d) =>
                  _updateFromDx(d.localPosition.dx, width),
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: (DragUpdateDetails d) =>
                  _updateFromDx(d.localPosition.dx, width),
              onHorizontalDragEnd: (_) => setState(() => _dragging = false),
              onHorizontalDragCancel: () => setState(() => _dragging = false),
              child: SizedBox(
                height: _boxHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    // Pista + relleno.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_trackHeight / 2),
                      child: SizedBox(
                        width: width,
                        height: _trackHeight,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: ColoredBox(color: AppColors.whiteA(0.10)),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: thumbLeft + _thumb / 2,
                              child: const ColoredBox(color: AppColors.cyan),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botón circular.
                    Positioned(
                      left: thumbLeft,
                      top: (_boxHeight - _thumb) / 2,
                      child: Container(
                        width: _thumb,
                        height: _thumb,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A0A0A),
                          border: Border.all(color: AppColors.cyan),
                          boxShadow: <BoxShadow>[
                            const BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                            if (ring)
                              BoxShadow(
                                color: AppColors.cyanA(0.5),
                                spreadRadius: 4,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Slider de valores enteros de paso 1 (Información Personal: 0 a 10).
class FzSlider extends StatelessWidget {
  const FzSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 10,
    this.semanticLabel,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FzStepSlider(
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      step: 1,
      semanticLabel: semanticLabel,
      onChanged: (double v) => onChanged(v.round()),
    );
  }
}

/// Etiqueta + valor "n/10" + slider (Información Personal).
class FzSliderField extends StatelessWidget {
  const FzSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.gap = 0,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  /// Espacio entre la fila de la etiqueta y el slider.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FzLabel(label),
            Text(
              '$value/10',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.cyanLight,
                height: 1.43,
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        FzSlider(value: value, onChanged: onChanged, semanticLabel: label),
      ],
    );
  }
}

/// Etiqueta + valor con texto libre + slider con paso + rótulos opcionales
/// de mínimo y máximo debajo (Hábitos de Entrenamiento).
class FzStepSliderField extends StatelessWidget {
  const FzStepSliderField({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.minLabel,
    this.maxLabel,
  });

  final String label;

  /// Texto del valor actual, p. ej. "3 días".
  final String valueText;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String? minLabel;
  final String? maxLabel;

  @override
  Widget build(BuildContext context) {
    final TextStyle captionStyle = AppText.body(
      size: 12,
      color: AppColors.whiteA(0.30),
      height: 1.333,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FzLabel(label),
            Text(
              valueText,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.cyanLight,
                height: 1.43,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FzStepSlider(
          value: value,
          min: min,
          max: max,
          step: step,
          semanticLabel: label,
          onChanged: onChanged,
        ),
        if (minLabel != null || maxLabel != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(minLabel ?? '', style: captionStyle),
              Text(maxLabel ?? '', style: captionStyle),
            ],
          ),
      ],
    );
  }
}