import 'package:flutter/material.dart';

import '../config/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Inicio',
      ),
      (
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Estadísticas',
      ),
      (
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        label: 'Mi Plan',
      ),
      (
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Config',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xEE000000),
        border: Border(
          top: BorderSide(
            color: Colors.white12,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) {
                final item = items[index];
                final active = currentIndex == index;

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? (AppColors.cyan.withValues(alpha: .15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active
                              ? item.activeIcon
                              : item.icon,
                          color: active
                              ? AppColors.cyanLight
                              : Colors.white60,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: active
                                ? AppColors.cyanLight
                                : Colors.white60,
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}