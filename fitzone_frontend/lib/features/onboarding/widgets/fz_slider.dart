import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'fz_label.dart';

/// Slider de valores enteros con el estilo del diseño: pista de 16 px,
/// relleno cian y botón circular con borde cian.
class FzSlider extends StatefulWidget {
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
  State<FzSlider> createState() => _FzSliderState();
}

class _FzSliderState extends State<FzSlider> {
  static const double _thumb = 16;
  static const double _trackHeight = 16;
  static const double _boxHeight = 24;

  bool _hover = false;
  bool _dragging = false;

  int _clamp(int v) => math.max(widget.min, math.min(widget.max, v));

  void _set(int v) {
    final int next = _clamp(v);
    if (next != widget.value) widget.onChanged(next);
  }

  void _updateFromDx(double dx, double width) {
    final double travel = width - _thumb;
    if (travel <= 0) return;
    final double t = ((dx - _thumb / 2) / travel).clamp(0.0, 1.0).toDouble();
    _set((widget.min + t * (widget.max - widget.min)).round());
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: '${widget.value}',
      increasedValue: '${_clamp(widget.value + 1)}',
      decreasedValue: '${_clamp(widget.value - 1)}',
      onIncrease: () => _set(widget.value + 1),
      onDecrease: () => _set(widget.value - 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double travel = width - _thumb;
            final double t =
                (widget.value - widget.min) / (widget.max - widget.min);
            final double thumbLeft = t * travel;
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

/// Etiqueta + valor "n/10" + slider.
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