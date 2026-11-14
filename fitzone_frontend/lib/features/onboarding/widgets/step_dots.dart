import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Puntos de navegación: el paso actual es una píldora alargada.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: i == current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: i == current
                    ? const LinearGradient(
                        colors: <Color>[AppColors.cyan, AppColors.teal],
                      )
                    : null,
                color: i == current
                    ? null
                    : i < current
                        ? AppColors.cyanA(0.5)
                        : AppColors.whiteA(0.15),
              ),
            ),
          ),
      ],
    );
  }
}