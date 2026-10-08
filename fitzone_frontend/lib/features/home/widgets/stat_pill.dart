import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Pastilla con ícono de color + texto (cabecera de Inicio).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.whiteA(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            softWrap: false,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w500,
              color: Colors.white,
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }
}