import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tarjeta base de Inicio: fondo y borde translúcidos, esquinas de 16 px.
class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.whiteA(0.07), AppColors.whiteA(0.035)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.whiteA(0.09)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, AppColors.isLight ? 0.05 : 0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}