import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/fade_slide_in.dart';
import 'data/plans_data.dart';
import 'models/plan.dart';
import 'widgets/continuing_indicator.dart';
import 'widgets/fz_logo.dart';
import 'widgets/plan_card.dart';
import '../../core/widgets/shimmer_top_bar.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key, required this.onSelectPlan});

  final ValueChanged<PlanId> onSelectPlan;

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  PlanId? _selected;
  Timer? _navTimer;

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  void _handleSelect(PlanId id) {
    _navTimer?.cancel(); // evita navegar dos veces si tocan rápido
    setState(() => _selected = id);
    _navTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) widget.onSelectPlan(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // ── Fondo ambiental ──
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.12),
              centerX: 0.5,
              centerY: 0.0,
              radiusX: 0.65,
              radiusY: 0.45,
              fadeStop: 0.6,
            ),
          ),
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.tealA(0.08),
              centerX: 0.85,
              centerY: 0.85,
              radiusX: 0.55,
              radiusY: 0.55,
              fadeStop: 0.6,
            ),
          ),

          // ── Contenido ──
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: 480,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _buildHeader(),
                                const SizedBox(height: 28),
                                _buildPlans(),
                              ],
                            ),
                            _buildBottom(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Barra brillante superior ──
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ShimmerTopBar(),
          ),
        ],
      ),
    );
  }

  // ── Encabezado ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return FadeSlideIn(
      offsetY: -16,
      child: Column(
        children: <Widget>[
          const FzLogo(),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              style: AppText.display(
                size: 31.2,
                letterSpacing: -0.78,
                height: 1.15,
              ),
              children: const <TextSpan>[
                TextSpan(text: 'Bienvenido a '),
                TextSpan(
                  text: 'FitZone',
                  style: TextStyle(color: AppColors.cyan),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Elige el plan que mejor se adapta a tus metas',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 14.08,
              color: AppColors.whiteA(0.52),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjetas de planes ────────────────────────────────────────────────────
  Widget _buildPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < kPlans.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 14),
          FadeSlideIn(
            delay: Duration(milliseconds: 80 + i * 100),
            child: PlanCard(
              plan: kPlans[i],
              isSelected: _selected == kPlans[i].id,
              onSelect: () => _handleSelect(kPlans[i].id),
            ),
          ),
        ],
      ],
    );
  }

  // ── Parte inferior: "Continuando..." o nota al pie ────────────────────────
  Widget _buildBottom() {
    if (_selected != null) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ContinuingIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        'Puedes cambiar o cancelar tu plan en cualquier momento',
        textAlign: TextAlign.center,
        style: AppText.body(
          size: 11.2,
          color: AppColors.whiteA(0.22),
          height: 1.5,
        ),
      ),
    );
  }
}