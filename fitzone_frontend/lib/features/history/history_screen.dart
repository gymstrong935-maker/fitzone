
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/sub_screen_frame.dart';
import 'data/history_data.dart';

/// Pantalla "Historial".
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  static const Color _orange500 = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = kWorkoutHistory.fold<int>(
      0,
      (int sum, WorkoutEntry w) => sum + w.duration,
    );
    final int totalCalories = kWorkoutHistory.fold<int>(
      0,
      (int sum, WorkoutEntry w) => sum + w.calories,
    );

    return SubScreenFrame(
      title: 'Historial',
      subtitle: 'Entrenamientos realizados',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Resumen ──
          Row(
            children: <Widget>[
              const Expanded(
                child: _SummaryTile(
                  label: 'Esta semana',
                  value: '3',
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  label: 'Total min',
                  value: '$totalMinutes',
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  label: 'Total kcal',
                  value: '$totalCalories',
                  color: _orange500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Entrenamientos ──
          for (int i = 0; i < kWorkoutHistory.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            FadeSlideIn(
              delay: Duration(milliseconds: i * 50),
              duration: const Duration(milliseconds: 400),
              offsetY: 8,
              child: _WorkoutCard(entry: kWorkoutHistory[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              color: color,
              height: 1.556,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.40),
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.entry});

  final WorkoutEntry entry;

  static const Color _green400 = Color(0xFF4ADE80);
  static const Color _orange400 = Color(0xFFFB923C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(52, 211, 153, 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.check_rounded, size: 18, color: _green400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.name,
                  style: AppText.display(
                    size: 14,
                    weight: FontWeight.w700,
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatWorkoutDate(entry.date),
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.40),
                    height: 1.333,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${entry.calories} kcal',
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: _orange400,
                  height: 1.333,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.history_rounded,
                    size: 12,
                    color: AppColors.whiteA(0.40),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.duration} min',
                    style: AppText.body(
                      size: 12,
                      color: AppColors.whiteA(0.40),
                      height: 1.333,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}