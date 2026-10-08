import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/home_data.dart';
import 'home_card.dart';

/// "Progreso Semanal": porcentaje, barra animada y los 7 días de la semana.
class WeeklyProgressCard extends StatefulWidget {
  const WeeklyProgressCard({
    super.key,
    required this.weekProgress,
    required this.weeklyGoal,
    required this.onSeeMore,
  });

  /// 7 valores (lunes a domingo): `true` = día completado.
  final List<bool> weekProgress;

  /// Meta de entrenamientos por semana.
  final int weeklyGoal;
  final VoidCallback onSeeMore;

  @override
  State<WeeklyProgressCard> createState() => _WeeklyProgressCardState();
}

class _WeeklyProgressCardState extends State<WeeklyProgressCard> {
  static const Color _ink = Color(0xFF0A0A0A);

  Timer? _barTimer;
  bool _barStarted = false;

  @override
  void initState() {
    super.initState();
    // La barra empieza a llenarse 0.35 s después de aparecer la tarjeta.
    _barTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _barStarted = true);
    });
  }

  @override
  void dispose() {
    _barTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int done = widget.weekProgress.where((bool d) => d).length;
    final int goal = math.max(widget.weeklyGoal, 1);
    final double pct = math.min(done / goal * 100, 100).toDouble();

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Título + "Ver más" ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Progreso Semanal',
                style: AppText.display(size: 16, height: 1.5),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSeeMore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Ver más',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w500,
                          color: AppColors.cyanLight,
                          height: 1.333,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.cyanLight,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Porcentaje ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Completado',
                style: AppText.body(
                  size: 12,
                  color: AppColors.whiteA(0.45),
                  height: 1.333,
                ),
              ),
              Text(
                '${pct.round()}%',
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.cyanLight,
                  height: 1.333,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Barra de progreso ──
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ColoredBox(color: AppColors.whiteA(0.08)),
                  ),
                  Positioned.fill(
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      alignment: Alignment.centerLeft,
                      widthFactor: _barStarted ? pct / 100 : 0,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                          gradient: LinearGradient(
                            colors: <Color>[AppColors.cyan, AppColors.teal],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Los 7 días ──
          Row(
            children: <Widget>[
              for (int i = 0; i < 7; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _buildDay(i)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDay(int i) {
    final bool done = i < widget.weekProgress.length && widget.weekProgress[i];
    final String day = kWeekDays[i];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: done
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[AppColors.cyan, AppColors.teal],
                    )
                  : null,
              color: done ? null : AppColors.whiteA(0.07),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: _ink)
                : Text(
                    day,
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.whiteA(0.30),
                      height: 1.333,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.30),
            height: 1.333,
          ),
        ),
      ],
    );
  }
}