import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'data/trainers_data.dart';
import 'models/trainer.dart';
import 'widgets/onboarding_shell.dart';
import 'widgets/trainer_card.dart';

class TrainerSelectionScreen extends StatefulWidget {
  const TrainerSelectionScreen({
    super.key,
    required this.isFree,
    required this.onNext,
    this.onBack,
    this.initialTrainer,
    this.step = 0,
    this.totalSteps = 6,
  });

  /// true = plan gratuito (oculta precios y muestra "Gratis durante 3 días").
  final bool isFree;

  /// Se llama con el entrenador elegido al pulsar "Siguiente".
  final ValueChanged<Trainer> onNext;

  /// En el diseño, el primer paso no tiene botón de volver (null = oculto).
  final VoidCallback? onBack;
  final Trainer? initialTrainer;

  /// Posición de este paso dentro del onboarding (base 0) y total de pasos.
  final int step;
  final int totalSteps;

  @override
  State<TrainerSelectionScreen> createState() => _TrainerSelectionScreenState();
}

class _TrainerSelectionScreenState extends State<TrainerSelectionScreen> {
  Trainer? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTrainer;
  }

  void _handleNext() {
    final Trainer? trainer = _selected;
    if (trainer != null) widget.onNext(trainer);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: widget.step,
      totalSteps: widget.totalSteps,
      nextEnabled: _selected != null,
      onNext: _handleNext,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 24),
          _buildBenefits(),
          const SizedBox(height: 20),
          for (int i = 0; i < kTrainers.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            TrainerCard(
              trainer: kTrainers[i],
              isSelected: _selected?.id == kTrainers[i].id,
              isFree: widget.isFree,
              onTap: () => setState(() => _selected = kTrainers[i]),
            ),
          ],
        ],
      ),
    );
  }

  // ── Encabezado ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cyanA(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyanA(0.25)),
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            size: 28,
            color: AppColors.cyanLight,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Selecciona tu Entrenador',
          textAlign: TextAlign.center,
          style: AppText.display(size: 24, letterSpacing: -0.48, height: 1.33),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige al profesional que mejor se adapte a ti',
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 14,
            color: AppColors.whiteA(0.5),
            height: 1.43,
          ),
        ),
      ],
    );
  }

  // ── "¿Por qué necesitas un entrenador?" ───────────────────────────────────
  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanA(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '¿Por qué necesitas un entrenador?',
            style: AppText.display(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.cyanLight,
            ),
          ),
          const SizedBox(height: 12),
          // Cuadrícula de 2 columnas; cada fila con la misma altura.
          for (int row = 0; row < kTrainerBenefits.length; row += 2) ...<Widget>[
            if (row > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _BenefitTile(benefit: kTrainerBenefits[row])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: row + 1 < kTrainerBenefits.length
                        ? _BenefitTile(benefit: kTrainerBenefits[row + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.benefit});

  final TrainerBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            benefit.icon,
            style: const TextStyle(fontSize: 20, height: 1.4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  benefit.title,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.description,
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.5),
                    height: 1.25,
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