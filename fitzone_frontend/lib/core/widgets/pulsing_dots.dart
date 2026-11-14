import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tres puntos que pulsan en secuencia (indicador de carga).
class PulsingDots extends StatefulWidget {
  const PulsingDots({
    super.key,
    this.color = AppColors.cyan,
    this.dotSize = 6,
    this.gap = 6,
  });

  final Color color;
  final double dotSize;
  final double gap;

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Intensidad 0..1 del punto según su fase dentro del ciclo.
  double _intensity(double phase) {
    if (phase < 0.35) return Curves.easeInOut.transform(phase / 0.35);
    if (phase < 0.75) {
      return 1 - Curves.easeInOut.transform((phase - 0.35) / 0.40);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : widget.gap),
                child: _buildDot(
                  _intensity((_controller.value - i * 0.15) % 1.0),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDot(double v) {
    return Opacity(
      opacity: 0.35 + 0.65 * v,
      child: Transform.scale(
        scale: 0.6 + 0.5 * v,
        child: Container(
          width: widget.dotSize,
          height: widget.dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}