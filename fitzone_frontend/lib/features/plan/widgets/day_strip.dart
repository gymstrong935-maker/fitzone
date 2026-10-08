import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/plan_data.dart';

/// Tira de 7 botones (L M X J V S D) con un punto de estado debajo de cada uno.
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.workouts,
    required this.expandedDay,
    required this.todayIndex,
    required this.onTap,
  });

  final List<WeekWorkout> workouts;
  final int? expandedDay;
  final int todayIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < workouts.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _DayButton(
              workout: workouts[i],
              selected: expandedDay == i,
              isToday: i == todayIndex,
              onTap: () => onTap(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.workout,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final WeekWorkout workout;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? AppColors.cyanA(0.20)
        : isToday
            ? AppColors.whiteA(0.10)
            : AppColors.whiteA(0.04);

    final Color border = selected
        ? AppColors.cyanA(0.40)
        : isToday
            ? AppColors.whiteA(0.15)
            : AppColors.whiteA(0.07);

    final Color textColor = selected
        ? AppColors.cyan
        : isToday
            ? Colors.white
            : AppColors.whiteA(0.40);

    return Semantics(
      button: true,
      selected: selected,
      label: workout.day,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: textColor,
                    height: 1.333,
                  ),
                  child: Text(workout.short),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: workout.completed
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[AppColors.cyan, AppColors.teal],
                          )
                        : null,
                    color: workout.completed
                        ? null
                        : workout.rest
                            ? AppColors.whiteA(0.20)
                            : AppColors.whiteA(0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}