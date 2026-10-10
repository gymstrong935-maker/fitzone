import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import 'data/plans_data.dart';
import 'models/plan.dart';
import 'widgets/continuing_indicator.dart';
import 'widgets/fz_logo.dart';
import 'widgets/plan_card.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({
    super.key,
    required this.onSelectPlan,
    this.plans = kPlans,
    this.errorMessage,
    this.onRetry,
    this.allowFree = true,
    this.onLogout,
  });

  final ValueChanged<PlanId> onSelectPlan;

  /// Planes a mostrar (por defecto, los del diseño).
  final List<Plan> plans;

  /// Si no se pudieron cargar los planes del servidor.
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// `false` oculta el plan gratuito (usuarios que ya tienen cuenta).
  final bool allowFree;

  /// Si se da, muestra "Cerrar sesión" abajo.
  final VoidCallback? onLogout;

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

  List<Plan> get _visiblePlans {
    return widget.plans
        .where((Plan p) => widget.allowFree || p.id != PlanId.free)
        .toList();
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
                                if (widget.errorMessage != null) ...<Widget>[
                                  _buildErrorBanner(),
                                  const SizedBox(height: 20),
                                ],
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

  // ── Aviso de error al cargar los planes ───────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(239, 68, 68, 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.22)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFFF87171)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: AppText.body(
                size: 12,
                color: const Color(0xFFF87171),
                height: 1.4,
              ),
            ),
          ),
          if (widget.onRetry != null) ...<Widget>[
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onRetry,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  'Reintentar',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
    final List<Plan> plans = _visiblePlans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < plans.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 14),
          FadeSlideIn(
            delay: Duration(milliseconds: 80 + i * 100),
            child: PlanCard(
              plan: plans[i],
              isSelected: _selected == plans[i].id,
              onSelect: () => _handleSelect(plans[i].id),
            ),
          ),
        ],
      ],
    );
  }

  // ── Parte inferior ────────────────────────────────────────────────────────
  Widget _buildBottom() {
    if (_selected != null) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ContinuingIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: <Widget>[
          Text(
            'Puedes cambiar o cancelar tu plan en cualquier momento',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 11.2,
              color: AppColors.whiteA(0.22),
              height: 1.5,
            ),
          ),
          if (widget.onLogout != null) ...<Widget>[
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onLogout,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Cerrar sesión',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.whiteA(0.45),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}