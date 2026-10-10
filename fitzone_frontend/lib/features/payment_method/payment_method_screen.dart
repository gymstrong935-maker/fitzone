import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import '../plan_selection/models/plan.dart';
import 'data/payment_methods_data.dart';
import 'models/payment_models.dart';
import 'widgets/payment_method_card.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({
    super.key,
    required this.planType,
    required this.onContinue,
    required this.onBack,
  });

  /// Plan elegido (mensual o anual). Se muestra en la etiqueta superior.
  final PlanId planType;

  /// Se llama al pulsar "Continuar". Si lanza [ApiException], se muestra el
  /// mensaje y el usuario puede intentarlo otra vez.
  final Future<void> Function(PayMethod method) onContinue;
  final VoidCallback onBack;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PayMethod? _selected;
  bool _confirming = false;
  String _error = '';

  Future<void> _handleContinue() async {
    final PayMethod? method = _selected;
    if (method == null || _confirming) return;

    setState(() {
      _confirming = true;
      _error = '';
    });

    try {
      await widget.onContinue(method);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // ── Brillo ambiental ──
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.09),
              centerX: 0.5,
              centerY: 0.15,
              radiusX: 0.55,
              radiusY: 0.40,
              fadeStop: 0.65,
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
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildTop(),
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

  // ── Parte superior: volver + encabezado + tarjetas ──────────────────────
  Widget _buildTop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: _BackButton(onTap: widget.onBack),
        ),
        const SizedBox(height: 32),
        FadeSlideIn(
          duration: const Duration(milliseconds: 450),
          offsetY: 20,
          child: _buildHeader(),
        ),
        const SizedBox(height: 32),
        for (int i = 0; i < kPaymentMethods.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          FadeSlideIn(
            delay: Duration(milliseconds: 100 + i * 80),
            duration: const Duration(milliseconds: 450),
            offsetY: 20,
            child: PaymentMethodCard(
              option: kPaymentMethods[i],
              isSelected: _selected == kPaymentMethods[i].id,
              onTap: () {
                if (_confirming) return;
                setState(() => _selected = kPaymentMethods[i].id);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final String planLabel =
        widget.planType == PlanId.annual ? 'Plan Anual' : 'Plan Mensual';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyanA(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cyanA(0.25)),
          ),
          child: Text(
            planLabel.toUpperCase(),
            style: AppText.body(
              size: 11.52,
              weight: FontWeight.w600,
              color: AppColors.cyan,
              letterSpacing: 0.92,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Método de pago',
          style: AppText.display(size: 28, letterSpacing: -0.56, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          'Selecciona cómo quieres pagar tu suscripción',
          style: AppText.body(size: 14.08, color: AppColors.whiteA(0.5)),
        ),
      ],
    );
  }

  // ── Parte inferior: nota + botón Continuar ──────────────────────────────
  Widget _buildBottom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cyanA(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyanA(0.15)),
          ),
          child: Text(
            'Tu suscripción será activada una vez que el equipo de FitZone confirme tu pago.',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12.8,
              color: AppColors.whiteA(0.5),
              height: 1.5,
            ),
          ),
        ),
        if (_error.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          ErrorBox(_error),
        ],
        const SizedBox(height: 24),
        _ContinueButton(
          hasSelection: _selected != null,
          confirming: _confirming,
          onTap: _handleContinue,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppColors.whiteA(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'Volver',
                style: AppText.body(size: 14.08, color: AppColors.whiteA(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón "Continuar": deshabilitado (gris) hasta elegir un método.
class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.hasSelection,
    required this.confirming,
    required this.onTap,
  });

  final bool hasSelection;
  final bool confirming;
  final VoidCallback onTap;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.hasSelection;
    final bool clickable = active && !widget.confirming;

    final Color contentColor =
        active ? const Color(0xFF0A0A0A) : AppColors.whiteA(0.3);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: clickable ? (_) => _setPressing(true) : null,
      onTapUp: (_) => _setPressing(false),
      onTapCancel: () => _setPressing(false),
      onTap: clickable ? widget.onTap : null,
      child: AnimatedScale(
        scale: (_pressing && clickable) ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.confirming ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: active
                  ? const LinearGradient(
                      colors: <Color>[AppColors.cyan, AppColors.teal],
                    )
                  : null,
              color: active ? null : AppColors.whiteA(0.06),
              border: active
                  ? null
                  : Border.all(color: AppColors.whiteA(0.10)),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.cyanA(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : <BoxShadow>[],
            ),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: contentColor),
              duration: const Duration(milliseconds: 250),
              builder: (BuildContext context, Color? color, Widget? _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      widget.confirming ? 'Procesando...' : 'Continuar',
                      style: AppText.body(
                        size: 15.2,
                        weight: FontWeight.w600,
                        color: color ?? contentColor,
                      ),
                    ),
                    if (!widget.confirming) ...<Widget>[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: color ?? contentColor,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}