import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.teal = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// `false` = acento cian, `true` = acento turquesa.
  final bool teal;

  @override
  Widget build(BuildContext context) {
    final Color background =
        teal ? AppColors.tealA(0.15) : AppColors.cyanA(0.15);
    final Color border = teal ? AppColors.tealA(0.25) : AppColors.cyanA(0.25);
    final Color iconColor =
        teal ? const Color(0xFF2DD4BF) : AppColors.cyanLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.display(size: 24, letterSpacing: -0.48, height: 1.33),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 14,
            color: AppColors.whiteA(0.5),
            height: 1.43,
          ),
        ),
      ],
    );
  }
}