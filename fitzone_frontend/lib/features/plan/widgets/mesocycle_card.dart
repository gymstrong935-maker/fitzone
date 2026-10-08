import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/ellipse_glow.dart';
import '../data/plan_data.dart';

/// Tarjeta morada "Mesociclo Actual".
class MesocycleCard extends StatelessWidget {
  const MesocycleCard({super.key, required this.mesocycle});

  final Mesocycle mesocycle;

  static const Color _violet = Color.fromRGBO(124, 58, 237, 1);
  static const Color _purple300 = Color(0xFFD8B4FE);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.fromRGBO(124, 58, 237, 0.25),
            Color.fromRGBO(236, 72, 153, 0.15),
          ],
        ),
        border: Border.all(color: _violet.withAlpha(77)), // 30 %
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: EllipseGlow(
              color: _violet.withAlpha(38), // 15 %
              centerX: 0.8,
              centerY: 0.2,
              radiusX: 0.6,
              radiusY: 0.6,
              fadeStop: 0.7,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'MESOCICLO ACTUAL',
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.50),
                            letterSpacing: 0.3,
                            height: 1.333,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mesocycle.phase,
                          style: AppText.display(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.556,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text.rich(
                          TextSpan(
                            text: '${mesocycle.currentWeek}',
                            style: AppText.display(
                              size: 24,
                              weight: FontWeight.w700,
                              color: _purple300,
                              height: 1.333,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '/${mesocycle.totalWeeks}',
                                style: AppText.display(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: AppColors.whiteA(0.40),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'semanas',
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.45),
                            height: 1.333,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedProgressBar(
                  value: mesocycle.progress,
                  height: 6,
                  duration: const Duration(milliseconds: 800),
                  trackColor: AppColors.whiteA(0.12),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFA78BFA), Color(0xFFEC4899)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Semana ${mesocycle.deloadWeek}: Descarga HIIT y recuperación activa',
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.40),
                    height: 1.333,
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