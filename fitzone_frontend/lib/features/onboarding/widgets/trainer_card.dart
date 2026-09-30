import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/trainer.dart';

/// Tarjeta de un entrenador. En plan gratuito oculta el precio y muestra
/// el aviso "Gratis durante 3 días".
class TrainerCard extends StatefulWidget {
  const TrainerCard({
    super.key,
    required this.trainer,
    required this.isSelected,
    required this.isFree,
    required this.onTap,
  });

  final Trainer trainer;
  final bool isSelected;
  final bool isFree;
  final VoidCallback onTap;

  @override
  State<TrainerCard> createState() => _TrainerCardState();
}

class _TrainerCardState extends State<TrainerCard> {
  static const Color _yellowStar = Color(0xFFFACC15);
  static const Color _tealText = Color(0xFF2DD4BF);

  bool _pressing = false;

  Trainer get _t => widget.trainer;
  bool get _selected => widget.isSelected;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: _selected,
      label: '${_t.name}, ${_t.specialty}',
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
              color: _selected ? AppColors.cyanA(0.09) : AppColors.whiteA(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selected ? AppColors.cyan : AppColors.whiteA(0.10),
                width: 1.5,
              ),
              boxShadow: _selected
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
                    _TrainerPhoto(url: _t.photo, name: _t.name),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfo()),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _t.description,
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
                    for (final String cert in _t.certifications)
                      _CertChip(label: cert),
                  ],
                ),
                if (widget.isFree) ...<Widget>[
                  const SizedBox(height: 10),
                  _buildFreeBanner(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Nombre, especialidad, precio, check y valoración ────────────────────
  Widget _buildInfo() {
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
                    _t.name,
                    style: AppText.display(size: 18, height: 1.25),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _t.specialty,
                    style: AppText.body(
                      size: 12,
                      color: AppColors.cyanLight,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isFree) ...<Widget>[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '\$${_t.price}',
                    style: AppText.body(
                      size: 16,
                      weight: FontWeight.w700,
                      color: _tealText,
                    ),
                  ),
                  Text(
                    _t.priceDescription,
                    style: AppText.body(
                      size: 12,
                      color: AppColors.whiteA(0.4),
                    ),
                  ),
                ],
              ),
            ],
            if (_selected) ...<Widget>[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 2,
          children: <Widget>[
            const Text(
              '⭐',
              style: TextStyle(fontSize: 12, color: _yellowStar),
            ),
            Text('${_t.rating}', style: AppText.body(size: 12)),
            Text(
              '•',
              style: AppText.body(size: 12, color: AppColors.whiteA(0.3)),
            ),
            Text(
              '${_t.experience} años exp.',
              style: AppText.body(size: 12, color: AppColors.whiteA(0.5)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tealA(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tealA(0.25)),
      ),
      child: Text(
        'Gratis durante 3 días',
        style: AppText.body(
          size: 12,
          weight: FontWeight.w600,
          color: _tealText,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _CertChip extends StatelessWidget {
  const _CertChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.body(
          size: 12,
          color: AppColors.whiteA(0.6),
          height: 1.33,
        ),
      ),
    );
  }
}

/// Foto 64x64 desde la red. Si no carga (o mientras carga) muestra las iniciales.
class _TrainerPhoto extends StatelessWidget {
  const _TrainerPhoto({required this.url, required this.name});

  final String url;
  final String name;

  String get _initials {
    final List<String> parts =
        name.split(' ').where((String p) => p.isNotEmpty).toList();
    return parts.take(2).map((String p) => p[0]).join().toUpperCase();
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.cyanA(0.25), AppColors.tealA(0.15)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppText.display(size: 20, color: AppColors.cyan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
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
            return progress == null ? child : _fallback();
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return _fallback();
          },
        ),
      ),
    );
  }
}