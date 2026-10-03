import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../data/plan_data.dart';

/// Tarjeta "Recuperación y Bienestar" con 3 accesos.
class RecoveryCard extends StatelessWidget {
  const RecoveryCard({super.key});

  static const Color _cyan400 = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🧘', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Recuperación y Bienestar',
                      style: AppText.display(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activa tu recuperación muscular',
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
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < kRecoveryItems.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _RecoveryButton(item: kRecoveryItems[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryButton extends StatelessWidget {
  const _RecoveryButton({required this.item});

  final RecoveryItem item;

  @override
  Widget build(BuildContext context) {
    // El diseño aún no define ninguna acción para estos botones.
    return PressableScale(
      onTap: null,
      pressedScale: 0.96,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cyanA(0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cyanA(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(item.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w600,
                color: Colors.white,
                height: 1.333,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.duration,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12,
                color: RecoveryCard._cyan400,
                height: 1.333,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12,
                color: AppColors.whiteA(0.35),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}