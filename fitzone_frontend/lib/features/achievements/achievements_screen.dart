import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/sub_screen_frame.dart';
import 'data/achievements_data.dart';

/// Pantalla "Logros".
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  static const Color _yellow400 = Color(0xFFFACC15);
  static const Color _cyan400 = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    final int done = kAchievements.where((Achievement a) => a.done).length;
    final int total = kAchievements.length;

    return SubScreenFrame(
      title: 'Logros',
      subtitle: 'Metas alcanzadas',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Resumen ──
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryTile(
                  background: const Color.fromRGBO(234, 179, 8, 0.12),
                  border: const Color.fromRGBO(234, 179, 8, 0.25),
                  leading: const Icon(
                    Icons.emoji_events_outlined,
                    size: 20,
                    color: _yellow400,
                  ),
                  value: '$done',
                  valueColor: _yellow400,
                  label: 'Desbloqueados',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  background: AppColors.whiteA(0.05),
                  border: AppColors.whiteA(0.09),
                  leading: const Text('🎯', style: TextStyle(fontSize: 20)),
                  value: '${total - done}',
                  valueColor: Colors.white,
                  label: 'En progreso',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  background: AppColors.cyanA(0.08),
                  border: AppColors.cyanA(0.20),
                  leading: const Text('📊', style: TextStyle(fontSize: 20)),
                  value: '${(done / total * 100).round()}%',
                  valueColor: _cyan400,
                  label: 'Completado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Lista ──
          for (int i = 0; i < kAchievements.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            FadeSlideIn(
              delay: Duration(milliseconds: i * 60),
              duration: const Duration(milliseconds: 400),
              offsetY: 8,
              child: _AchievementCard(achievement: kAchievements[i], index: i),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.background,
    required this.border,
    required this.leading,
    required this.value,
    required this.valueColor,
    required this.label,
  });

  final Color background;
  final Color border;
  final Widget leading;
  final String value;
  final Color valueColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          leading,
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              color: valueColor,
              height: 1.556,
            ),
          ),
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

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.index});

  final Achievement achievement;
  final int index;

  static const Color _yellow400 = Color(0xFFFACC15);
  static const Color _yellow500 = Color(0xFFEAB308);

  @override
  Widget build(BuildContext context) {
    final Achievement a = achievement;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: a.done
            ? const Color.fromRGBO(234, 179, 8, 0.08)
            : AppColors.whiteA(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.done
              ? const Color.fromRGBO(234, 179, 8, 0.25)
              : AppColors.whiteA(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: a.done
                  ? const Color.fromRGBO(234, 179, 8, 0.20)
                  : AppColors.whiteA(0.07),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(a.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            a.title,
                            style: AppText.display(
                              size: 14,
                              weight: FontWeight.w700,
                              height: 1.43,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.description,
                            style: AppText.body(
                              size: 12,
                              color: AppColors.whiteA(0.50),
                              height: 1.625,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (a.done) ...<Widget>[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: _yellow400,
                      ),
                    ],
                  ],
                ),
                if (a.done)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      a.date ?? '',
                      style: AppText.body(
                        size: 12,
                        color: _yellow500.withAlpha(179), // 70 %
                        height: 1.333,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Progreso',
                              style: AppText.body(
                                size: 12,
                                color: AppColors.whiteA(0.40),
                                height: 1.333,
                              ),
                            ),
                            Text(
                              '${a.progress}%',
                              style: AppText.body(
                                size: 12,
                                color: AppColors.whiteA(0.40),
                                height: 1.333,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedProgressBar(
                          value: a.progress / 100,
                          height: 6,
                          delay: Duration(milliseconds: index * 60),
                          duration: const Duration(milliseconds: 600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}