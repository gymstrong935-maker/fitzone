import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ellipse_glow.dart';
import '../models/plan.dart';

class PlanCard extends StatefulWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  final Plan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _pressing = false;

  Plan get _plan => widget.plan;
  bool get _selected => widget.isSelected;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _selected
        ? AppColors.cyan
        : _plan.highlighted
            ? AppColors.cyanA(0.4)
            : AppColors.whiteA(0.1);

    final Color bgColor = _selected
        ? AppColors.cyanA(0.10)
        : _plan.highlighted
            ? AppColors.cyanA(0.055)
            : AppColors.whiteA(0.04);

    final List<BoxShadow> shadows = _selected
        ? <BoxShadow>[BoxShadow(color: AppColors.cyanA(0.20), blurRadius: 28)]
        : _plan.highlighted
            ? <BoxShadow>[
                BoxShadow(color: AppColors.cyanA(0.09), blurRadius: 18),
              ]
            : <BoxShadow>[];

    // Reemplazo del "inset box-shadow" de CSS: una línea de luz en el borde superior.
    final double topLightOpacity = _selected
        ? 0.06
        : _plan.highlighted
            ? 0.04
            : 0.03;

    return Semantics(
      button: true,
      selected: _selected,
      label: _plan.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressing(true),
        onTapUp: (_) => _setPressing(false),
        onTapCancel: () => _setPressing(false),
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _pressing ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: shadows,
            ),
            child: Stack(
              children: <Widget>[
                if (_plan.highlighted)
                  Positioned.fill(
                    child: EllipseGlow(
                      color: AppColors.cyanA(0.08),
                      centerX: 0.5,
                      centerY: -0.1,
                      radiusX: 0.7,
                      radiusY: 0.5,
                      fadeStop: 0.65,
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: 14,
                  right: 14,
                  height: 1,
                  child: ColoredBox(color: AppColors.whiteA(topLightOpacity)),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildTopRow(),
                      const SizedBox(height: 12),
                      Text(
                        _plan.description,
                        style: AppText.body(
                          size: 13.12,
                          color: AppColors.whiteA(0.55),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatures(),
                      const SizedBox(height: 16),
                      _buildCta(),
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

  // ── Fila superior: icono + nombre | badge + precio ──────────────────────
  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              _buildIconBox(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _plan.name,
                      style: AppText.display(size: 16, letterSpacing: -0.16),
                    ),
                    if (_plan.id == PlanId.free)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          'Sin tarjeta de crédito',
                          style: AppText.body(
                            size: 11.52,
                            color: AppColors.whiteA(0.42),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildPrice(),
      ],
    );
  }

  Widget _buildIconBox() {
    final bool accent = _plan.highlighted || _selected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: _plan.highlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.cyanA(0.28),
                  AppColors.tealA(0.16),
                ],
              )
            : null,
        color: _plan.highlighted
            ? null
            : (_selected ? AppColors.cyanA(0.15) : AppColors.whiteA(0.08)),
        border: Border.all(
          color: _plan.highlighted
              ? AppColors.cyanA(0.38)
              : AppColors.whiteA(0.1),
          width: 1,
        ),
      ),
      child: Icon(
        _plan.icon,
        size: 19,
        color: accent ? AppColors.cyan : AppColors.whiteA(0.65),
      ),
    );
  }

  Widget _buildPrice() {
    final double priceSize = _plan.price != null ? 20.8 : 17.6;
    final Color priceColor = _plan.highlighted
        ? AppColors.cyan
        : _selected
            ? AppColors.cyanLight
            : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_plan.badge != null) ...<Widget>[
          _plan.badgeStyle == PlanBadgeStyle.premium
              ? _PremiumBadge(label: _plan.badge!)
              : _NeutralBadge(label: _plan.badge!),
          const SizedBox(height: 6),
        ],
        Text(
          _plan.priceLabel,
          style: AppText.display(
            size: priceSize,
            color: priceColor,
            letterSpacing: -0.02 * priceSize,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          _plan.priceSub,
          style: AppText.body(size: 11.2, color: AppColors.whiteA(0.4)),
        ),
      ],
    );
  }

  // ── Lista de características ────────────────────────────────────────────
  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < _plan.features.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
            child: Row(
              children: <Widget>[
                Container(
                  width: 15,
                  height: 15,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _plan.highlighted
                        ? AppColors.cyanA(0.2)
                        : AppColors.whiteA(0.08),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 9,
                    color: _plan.highlighted
                        ? AppColors.cyan
                        : AppColors.whiteA(0.45),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _plan.features[i],
                    style: AppText.body(
                      size: 12.48,
                      color: AppColors.whiteA(0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Botón (CTA) ─────────────────────────────────────────────────────────
  Widget _buildCta() {
    final bool isFree = _plan.id == PlanId.free;

    late final Color foreground;
    late final BoxDecoration decoration;

    if (_plan.highlighted) {
      foreground = AppColors.background;
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          colors: <Color>[AppColors.cyan, AppColors.teal],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.cyanA(0.30),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isFree) {
      foreground = _selected ? AppColors.cyanLight : Colors.white;
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: _selected ? AppColors.cyanA(0.14) : AppColors.whiteA(0.07),
        border: Border.all(
          color: _selected ? AppColors.cyanA(0.5) : AppColors.whiteA(0.14),
        ),
      );
    } else {
      foreground = AppColors.cyan;
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: _selected ? AppColors.cyanA(0.14) : AppColors.cyanA(0.08),
        border: Border.all(
          color: _selected ? AppColors.cyanA(0.5) : AppColors.cyanA(0.25),
        ),
      );
    }

    final TextStyle textStyle = AppText.body(
      size: 14.08,
      weight: FontWeight.w600,
      color: foreground,
    );

    return AnimatedOpacity(
      opacity: _pressing ? 0.75 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        decoration: decoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _selected
              ? <Widget>[
                  Icon(Icons.check_rounded, size: 15, color: foreground),
                  const SizedBox(width: 8),
                  Text('Seleccionado', style: textStyle),
                ]
              : <Widget>[
                  Text(_plan.cta, style: textStyle),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      size: 15, color: foreground),
                ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Badges
// ═══════════════════════════════════════════════════════════════════════════

class _NeutralBadge extends StatelessWidget {
  const _NeutralBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteA(0.12)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.body(
          size: 9.92,
          weight: FontWeight.w700,
          color: AppColors.whiteA(0.55),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Badge "premium" con resplandor que pulsa (2.5 s por ciclo).
class _PremiumBadge extends StatefulWidget {
  const _PremiumBadge({required this.label});

  final String label;

  @override
  State<_PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<_PremiumBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.star_rounded, size: 9, color: AppColors.cyan),
          const SizedBox(width: 3),
          Text(
            widget.label.toUpperCase(),
            style: AppText.body(
              size: 9.92,
              weight: FontWeight.w700,
              color: AppColors.cyan,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
      builder: (BuildContext context, Widget? child) {
        final double p = _pulse.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[AppColors.cyanA(0.25), AppColors.tealA(0.18)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cyanA(0.4)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.cyanA(0.3 * p),
                blurRadius: 12 * p,
                spreadRadius: 3 * p,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}