import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Etiqueta de campo: pequeña, en mayúsculas y con espaciado entre letras.
class FzLabel extends StatelessWidget {
  const FzLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.body(
        size: 12,
        weight: FontWeight.w500,
        color: AppColors.whiteA(0.70),
        letterSpacing: 0.3,
        height: 1.333,
      ),
    );
  }
}