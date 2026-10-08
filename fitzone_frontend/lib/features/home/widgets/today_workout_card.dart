import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../data/home_data.dart';

/// Tarjeta turquesa "Rutina de hoy" con el botón "Comenzar Entrenamiento".
class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({
    super.key,
    required this.workout,
    required this.onStart,
  });

  final TodayWorkout workout;
  final VoidCallback onStart;

  static const Color _black65 = Color.fromRGBO(0, 0, 0, 0.65);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.cyan, AppColors.teal],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Círculos decorativos.
          const Positioned(
            top: -39.2,
            right: -39.2,
            width: 112,
            height: 112,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(255, 255, 255, 0.08),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: -28,
            left: -28,
            width: 80,
            height: 80,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'RUTINA DE HOY',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color.fromRGBO(0, 0, 0, 0.55),
                    letterSpacing: 1.2,
                    height: 1.333,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workout.name,
                  style: AppText.display(
                    size: 20,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    _Meta(
                      icon: Icons.calendar_today_outlined,
                      text: '${workout.exercises} ejercicios',
                    ),
                    const SizedBox(width: 16),
                    _Meta(
                      icon: Icons.monitor_heart_outlined,
                      text: '${workout.duration} min',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PressableScale(
                  onTap: onStart,
                  pressedScale: 0.96,
                  hoverScale: 1.02,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.82),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.35),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const _PulsingPlay(),
                        const SizedBox(width: 8),
                        Text(
                          'Comenzar Entrenamiento',
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.43,
                          ),
                        ),
                      ],
                    ),
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

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: TodayWorkoutCard._black65),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppText.body(
            size: 12,
            color: TodayWorkoutCard._black65,
            height: 1.333,
          ),
        ),
      ],
    );
  }
}

/// Ícono de "play" que late suavemente (1.8 s por ciclo).
class _PulsingPlay extends StatefulWidget {
  const _PulsingPlay();

  @override
  State<_PulsingPlay> createState() => _PulsingPlayState();
}

class _PulsingPlayState extends State<_PulsingPlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(scale: 1 + 0.15 * t, child: child);
      },
      child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
    );
  }
}