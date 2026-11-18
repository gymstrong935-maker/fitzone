import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fade_slide_in.dart';

/// Tres puntos animados + "Continuando..." que aparece al elegir un plan.
class ContinuingIndicator extends StatefulWidget {
  const ContinuingIndicator({super.key});

  @override
  State<ContinuingIndicator> createState() => _ContinuingIndicatorState();
}

class _ContinuingIndicatorState extends State<ContinuingIndicator>
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
    return FadeSlideIn(
      duration: const Duration(milliseconds: 300),
      offsetY: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      child: _buildDot(
                        _intensity((_controller.value - i * 0.15) % 1.0),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Continuando...',
            style: AppText.body(size: 12.48, color: AppColors.whiteA(0.45)),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double v) {
    return Opacity(
      opacity: 0.35 + 0.65 * v,
      child: Transform.scale(
        scale: 0.6 + 0.5 * v,
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan,
          ),
        ),
      ),
    );
  }
}