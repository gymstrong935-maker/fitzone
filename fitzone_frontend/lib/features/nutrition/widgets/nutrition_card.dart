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
        color: gradient == null ? (color ?? AppColors.whiteA(0.05)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? AppColors.whiteA(0.10)),
      ),
      child: child,
    );
  }
}