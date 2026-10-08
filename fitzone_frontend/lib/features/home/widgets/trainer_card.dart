import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../onboarding/models/trainer.dart';
import 'home_card.dart';

/// "Tu Entrenador": foto, nombre, especialidad, valoración y botón "Mensaje".
class TrainerCard extends StatelessWidget {
  const TrainerCard({super.key, required this.trainer, this.onMessage});

  final Trainer trainer;

  /// Acción del botón "Mensaje" (el diseño aún no define ninguna).
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Título + "Activo" ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Tu Entrenador', style: AppText.display(size: 16, height: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cyanA(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Activo',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.cyanLight,
                    height: 1.333,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Foto + datos + botón ──
          Row(
            children: <Widget>[
              _buildPhoto(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      trainer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(size: 16, height: 1.25),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trainer.specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 12,
                        color: AppColors.cyanLight,
                        height: 1.333,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Text('⭐', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${trainer.rating}',
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.55),
                            height: 1.333,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMessage,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.whiteA(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.whiteA(0.15)),
                  ),
                  child: Text(
                    'Mensaje',
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyanA(0.35), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          trainer.photo,
          fit: BoxFit.cover,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? progress,
          ) {
            if (progress == null) return child;
            return ColoredBox(color: AppColors.whiteA(0.08));
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return ColoredBox(
              color: AppColors.whiteA(0.08),
              child: Icon(
                Icons.person_outline_rounded,
                size: 24,
                color: AppColors.whiteA(0.4),
              ),
            );
          },
        ),
      ),
    );
  }
}