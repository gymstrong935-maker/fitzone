import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/trainer.dart';

/// Tarjeta seleccionable de un entrenador.
class TrainerCard extends StatefulWidget {
  const TrainerCard({
    super.key,
    required this.trainer,
    required this.isSelected,
    required this.onTap,
  });

  final Trainer trainer;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<TrainerCard> createState() => _TrainerCardState();
}

class _TrainerCardState extends State<TrainerCard> {
  static const Color _teal400 = Color(0xFF2DD4BF);
  static const Color _yellow400 = Color(0xFFFACC15);
  static const Color _ink = Color(0xFF0A0A0A);

  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final Trainer t = widget.trainer;
    final bool selected = widget.isSelected;

    return Semantics(
      button: true,
      selected: selected,
      label: t.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressing(true),
        onTapUp: (_) => _setPressing(false),
        onTapCancel: () => _setPressing(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressing ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AppColors.cyanA(0.09) : AppColors.whiteA(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.cyan : AppColors.whiteA(0.10),
                width: 1.5,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(color: AppColors.cyanA(0.12), blurRadius: 20),
                    ]
                  : <BoxShadow>[],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildPhoto(t.photo),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfo(t, selected)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  t.description,
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.6),
                    height: 1.625,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final String cert in t.certifications)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.whiteA(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          cert,
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Foto (con respaldo si no carga) ───────────────────────────────────────
  Widget _buildPhoto(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Image.network(
          url,
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
                size: 28,
                color: AppColors.whiteA(0.4),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Nombre, especialidad, precio, check y valoración ──────────────────────
  Widget _buildInfo(Trainer t, bool selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.name,
                    style: AppText.display(
                      size: 18,
                      weight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.specialty,
                    style: AppText.body(size: 12, color: AppColors.cyanLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '\$${t.price}',
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w700,
                    color: _teal400,
                  ),
                ),
                Text(
                  t.priceDescription,
                  style: AppText.body(size: 12, color: AppColors.whiteA(0.4)),
                ),
              ],
            ),
            if (selected) ...<Widget>[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan,
                ),
                child: const Icon(Icons.check_rounded, size: 12, color: _ink),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            const Icon(Icons.star_rounded, size: 14, color: _yellow400),
            const SizedBox(width: 6),
            Text('${t.rating}', style: AppText.body(size: 12)),
            const SizedBox(width: 6),
            Text(
              '•',
              style: AppText.body(size: 12, color: AppColors.whiteA(0.3)),
            ),
            const SizedBox(width: 6),
            Text(
              '${t.experience} años exp.',
              style: AppText.body(size: 12, color: AppColors.whiteA(0.5)),
            ),
          ],
        ),
      ],
    );
  }
}