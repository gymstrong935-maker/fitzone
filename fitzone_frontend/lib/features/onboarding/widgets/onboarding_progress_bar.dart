import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Barra de progreso fina (2 px) fija arriba de la pantalla.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({super.key, required this.progress});

  /// Valor de 0.0 a 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: ColoredBox(color: AppColors.whiteA(0.10))),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? _) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0).toDouble(),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[AppColors.cyan, AppColors.teal],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}