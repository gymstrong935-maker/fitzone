import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../widgets/step_header.dart';

class PlaceholderStep extends StatelessWidget {
  const PlaceholderStep({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.teal = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool teal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StepHeader(icon: icon, title: title, subtitle: subtitle, teal: teal),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.cyanA(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyanA(0.15)),
          ),
          child: Text(
            'Este paso lo construiremos en una de las siguientes pantallas.',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 13,
              color: AppColors.whiteA(0.5),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}