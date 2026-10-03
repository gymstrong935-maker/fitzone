import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/plan_data.dart';

/// Tarjeta de un día del plan. Al tocarla se expande y muestra los botones
/// "Iniciar" y "Ver" (si no es día de descanso).
class WorkoutDayCard extends StatelessWidget {
  const WorkoutDayCard({
    super.key,
    required this.workout,
    required this.isToday,
    required this.isExpanded,
    required this.onToggle,
    required this.onStart,
  });

  final WeekWorkout workout;
  final bool isToday;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onStart;

  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _ink = Colors.black;

  @override
  Widget build(BuildContext context) {
    final WeekWorkout w = workout;

    final Color borderColor = isExpanded
        ? AppColors.cyanA(0.35)
        : w.completed
            ? const Color.fromRGBO(52, 211, 153, 0.25)
            : w.rest
                ? AppColors.whiteA(0.08)
                : AppColors.whiteA(0.09);

    final Color background = isExpanded
        ? AppColors.cyanA(0.07)
        : w.completed
            ? const Color.fromRGBO(52, 211, 153, 0.07)
            : AppColors.whiteA(0.04);

    final bool showActions = isExpanded && !w.rest;

    return Semantics(
      button: true,
      expanded: isExpanded,
      label: '${w.day}: ${w.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildRow(),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: showActions
                        ? _buildActions()
                        : const SizedBox(
                            key: ValueKey<String>('collapsed'),
                            width: double.infinity,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Fila principal ────────────────────────────────────────────────────────
  Widget _buildRow() {
    final WeekWorkout w = workout;

    return Row(
      children: <Widget>[
        // Ícono de estado.
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: w.completed
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.cyan, AppColors.teal],
                  )
                : null,
            color: w.completed
                ? null
                : w.rest
                    ? AppColors.whiteA(0.08)
                    : AppColors.cyanA(0.12),
          ),
          child: w.completed
              ? const Icon(Icons.check_rounded, size: 20, color: _ink)
              : w.rest
                  ? const Text('😴', style: TextStyle(fontSize: 18))
                  : const Icon(
                      Icons.fitness_center_rounded,
                      size: 20,
                      color: AppColors.cyan,
                    ),
        ),
        const SizedBox(width: 12),

        // Día + nombre.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  text: '${w.day} ',
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.40),
                    height: 1.333,
                  ),
                  children: <TextSpan>[
                    if (isToday)
                      TextSpan(
                        text: '· Hoy',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: _cyan400,
                          height: 1.333,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                w.name,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        // Duración y número de ejercicios.
        if (!w.rest) ...<Widget>[
          const SizedBox(width: 12),
          _Meta(icon: Icons.access_time_rounded, text: '${w.duration}m'),
          const SizedBox(width: 12),
          _Meta(
            icon: Icons.calendar_today_outlined,
            text: '${w.exercises} ej.',
          ),
        ],
      ],
    );
  }

  // ── Acciones al expandir ──────────────────────────────────────────────────
  Widget _buildActions() {
    return Padding(
      key: const ValueKey<String>('actions'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: <Widget>[
          if (!workout.completed) ...<Widget>[
            Expanded(child: _StartButton(onTap: onStart)),
            const SizedBox(width: 8),
          ],
          // "Ver": el diseño aún no define ninguna acción. El onTap vacío
          // evita que el toque contraiga la tarjeta.
          _ViewButton(onTap: () {}),
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
        Icon(icon, size: 12, color: AppColors.whiteA(0.40)),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.40),
            height: 1.333,
          ),
        ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: <Color>[AppColors.cyan, AppColors.teal],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              'Iniciar',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: Colors.black,
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.whiteA(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.whiteA(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.visibility_outlined,
              size: 14,
              color: AppColors.whiteA(0.70),
            ),
            const SizedBox(width: 6),
            Text(
              'Ver',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.whiteA(0.70),
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }
}