import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/trainer.dart';

/// Panel "¿Por qué necesitas un entrenador?" con cuadrícula de 2 columnas.
class TrainerBenefitsPanel extends StatelessWidget {
  const TrainerBenefitsPanel({super.key, required this.benefits});

  final List<TrainerBenefit> benefits;

  @override
  Widget build(BuildContext context) {
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
          for (int i = 0; i < benefits.length; i += 2) ...<Widget>[
            if (i > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _BenefitCell(benefit: benefits[i])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < benefits.length
                        ? _BenefitCell(benefit: benefits[i + 1])
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

class _BenefitCell extends StatelessWidget {
  const _BenefitCell({required this.benefit});

  final TrainerBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(benefit.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  benefit.title,
                  style: AppText.body(size: 12, weight: FontWeight.w600),
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