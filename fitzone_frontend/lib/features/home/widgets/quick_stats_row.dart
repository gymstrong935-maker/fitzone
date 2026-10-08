import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Fila de 3 estadísticas rápidas: sesiones, minutos y energía.
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.sessions,
    required this.minutes,
    required this.energy,
  });

  final int sessions;
  final int minutes;
  final int energy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            color: AppColors.cyan,
            value: '$sessions',
            label: 'Sesiones',
            sub: 'esta semana',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.monitor_heart_outlined,
            color: AppColors.teal,
            value: '$minutes',
            label: 'Minutos',
            sub: 'por sesión',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_outlined,
            color: const Color(0xFFF97316),
            value: '$energy/10',
            label: 'Energía',
            sub: 'hoy',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.sub,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.display(size: 18, color: color, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.45),
              height: 1.333,
            ),
          ),
          Text(
            sub,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.25),
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }
}