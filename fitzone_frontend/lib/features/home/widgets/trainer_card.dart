import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../onboarding/models/trainer.dart';
import 'home_card.dart';

/// "Tu Entrenador": foto, nombre, especialidad, valoración y botón "Agendar".
class TrainerCard extends StatelessWidget {
  const TrainerCard({super.key, required this.trainer, this.onSchedule});

  final Trainer trainer;

  /// Abre la pantalla de citas.
  final VoidCallback? onSchedule;

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
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'Agendar cita',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSchedule,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: <Color>[AppColors.cyan, AppColors.teal],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.event_available_rounded,
                            size: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Agendar',
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF0A0A0A),
                            ),
                          ),
                        ],
                      ),
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
    final Widget fallback = ColoredBox(
      color: AppColors.whiteA(0.08),
      child: Icon(
        Icons.person_outline_rounded,
        size: 24,
        color: AppColors.whiteA(0.4),
      ),
    );

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
        child: trainer.photo.isEmpty
            ? fallback
            : Image.network(
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
                ) =>
                    fallback,
              ),
      ),
    );
  }
}