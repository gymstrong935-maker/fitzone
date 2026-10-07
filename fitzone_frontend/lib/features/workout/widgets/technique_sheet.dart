import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/exercise.dart';
import 'exercise_figure.dart';

/// Abre la hoja inferior "Ver técnica".
Future<void> showTechniqueSheet(BuildContext context, Exercise exercise) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xBF000000),
    constraints: const BoxConstraints(maxWidth: 512),
    builder: (BuildContext ctx) => _TechniqueSheet(exercise: exercise),
  );
}

class _TechniqueSheet extends StatelessWidget {
  const _TechniqueSheet({required this.exercise});

  final Exercise exercise;

  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _teal400 = Color(0xFF2DD4BF);
  static const Color _red400 = Color(0xFFF87171);

  @override
  Widget build(BuildContext context) {
    final ExerciseTechnique tech = exercise.technique;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.whiteA(0.10)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Asa.
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.whiteA(0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      _buildFigure(),
                      const SizedBox(height: 20),
                      _buildMuscles(tech),
                      const SizedBox(height: 16),
                      _buildBreathing(tech),
                      const SizedBox(height: 16),
                      _buildSteps(tech),
                      const SizedBox(height: 16),
                      _buildErrors(tech),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Encabezado ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cyanA(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  exercise.muscleGroup.toUpperCase(),
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.cyan,
                    letterSpacing: 1.2,
                    height: 1.333,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.name,
                style: AppText.display(
                  size: 20,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Cerrar',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whiteA(0.10),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.whiteA(0.70),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Animación ─────────────────────────────────────────────────────────────
  Widget _buildFigure() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanA(0.15)),
      ),
      child: ExerciseFigure(exerciseId: exercise.id, size: 180),
    );
  }

  // ── Músculos ──────────────────────────────────────────────────────────────
  Widget _buildMuscles(ExerciseTechnique tech) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionTitle(
          icon: Icons.track_changes_rounded,
          color: _cyan400,
          text: 'Músculos trabajados',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final String muscle in tech.muscles)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealA(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.tealA(0.25)),
                ),
                child: Text(
                  muscle,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.teal,
                    height: 1.333,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Respiración ───────────────────────────────────────────────────────────
  Widget _buildBreathing(ExerciseTechnique tech) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyanA(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionTitle(
            icon: Icons.air_rounded,
            color: _cyan400,
            text: 'Respiración',
          ),
          const SizedBox(height: 4),
          Text(
            tech.breathing,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.60),
              height: 1.625,
            ),
          ),
        ],
      ),
    );
  }

  // ── Técnica correcta ──────────────────────────────────────────────────────
  Widget _buildSteps(ExerciseTechnique tech) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionTitle(
          icon: Icons.bolt_rounded,
          color: _teal400,
          text: 'Técnica correcta',
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < tech.steps.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyanA(0.20),
                ),
                child: Text(
                  '${i + 1}',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.cyan,
                    height: 1.333,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tech.steps[i],
                  style: AppText.body(
                    size: 14,
                    color: AppColors.whiteA(0.70),
                    height: 1.625,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Errores frecuentes ────────────────────────────────────────────────────
  Widget _buildErrors(ExerciseTechnique tech) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionTitle(
          icon: Icons.error_outline_rounded,
          color: _red400,
          text: 'Errores frecuentes',
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < tech.errors.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(239, 68, 68, 0.07),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.close_rounded, size: 12, color: _red400),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tech.errors[i],
                    style: AppText.body(
                      size: 12,
                      color: AppColors.whiteA(0.60),
                      height: 1.625,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.whiteA(0.80),
            height: 1.43,
          ),
        ),
      ],
    );
  }
}