import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tarjeta base de Nutrición: esquinas de 24 px y borde de 1 px.
class NutritionCard extends StatelessWidget {
  const NutritionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.gradient,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Si se da un degradado, reemplaza al color de fondo.
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null && color != null ? color : null,
        gradient: gradient ??
            (color != null
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.whiteA(0.07), AppColors.whiteA(0.035)],
                  )),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? AppColors.whiteA(0.10)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, AppColors.isLight ? 0.05 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}