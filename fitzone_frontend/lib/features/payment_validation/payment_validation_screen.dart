import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/shimmer_top_bar.dart';

class PaymentValidationScreen extends StatefulWidget {
  const PaymentValidationScreen({
    super.key,
    required this.fetchStatus,
    required this.onApproved,
    required this.onSkip,
    required this.onChoosePlan,
    required this.onLogout,
    this.initialStatus,
  });

  /// Consulta el estado de la suscripción en el servidor.
  final Future<SubscriptionStatus> Function() fetchStatus;

  /// Se llama cuando el plan quedó activo.
  final VoidCallback onApproved;

  /// "Continuar mientras tanto" (el pago sigue en revisión).
  final VoidCallback onSkip;

  /// Pago rechazado / plan vencido: volver a elegir un plan.
  final VoidCallback onChoosePlan;

  final VoidCallback onLogout;
  final SubscriptionStatus? initialStatus;

  @override
  State<PaymentValidationScreen> createState() =>
      _PaymentValidationScreenState();
}

class _PaymentValidationScreenState extends State<PaymentValidationScreen> {
  Timer? _poll;
  Timer? _advance;

  late SubscriptionStatus _status =
      widget.initialStatus ?? SubscriptionStatus.pending;
  bool _checking = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _check());
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _advance?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);

    try {
      final SubscriptionStatus status = await widget.fetchStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = '';
      });

      if (status == SubscriptionStatus.active) {
        _poll?.cancel();
        _advance ??= Timer(const Duration(milliseconds: 1600), () {
          if (mounted) widget.onApproved();
        });
      } else if (status != SubscriptionStatus.pending) {
        _poll?.cancel();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.14),
              centerX: 0.5,
              centerY: 0.4,
              radiusX: 0.55,
              radiusY: 0.45,
              fadeStop: 0.68,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildBody(),
                ),
              ),
            ),
          ),
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

  Widget _buildBody() {
    switch (_status) {
      case SubscriptionStatus.active:
        return _buildMessage(
          success: true,
          title: '¡Pago validado!',
          message: 'Tu plan ya está activo. Te llevamos a configurar tu perfil.',
          actions: const <Widget>[],
        );
      case SubscriptionStatus.pending:
        return _buildMessage(
          title: 'Validando tu pago',
          message:
              'Tu pago está en revisión. El equipo de FitZone lo aprobará en breve y te avisaremos por correo. Esta pantalla se actualiza sola.',
          showDots: true,
          actions: <Widget>[
            _PrimaryButton(label: 'Continuar mientras tanto', onTap: widget.onSkip),
            const SizedBox(height: 12),
            _SecondaryButton(
              label: _checking ? 'Revisando...' : 'Actualizar estado',
              onTap: _checking ? null : _check,
            ),
          ],
        );
      case SubscriptionStatus.rejected:
        return _buildMessage(
          title: 'Pago rechazado',
          message:
              'El equipo de FitZone no pudo validar tu pago. Puedes elegir un plan e intentarlo de nuevo.',
          actions: <Widget>[
            _PrimaryButton(label: 'Elegir un plan', onTap: widget.onChoosePlan),
            const SizedBox(height: 12),
            _SecondaryButton(label: 'Cerrar sesión', onTap: widget.onLogout),
          ],
        );
      case SubscriptionStatus.expired:
        return _buildMessage(
          title: 'Tu plan venció',
          message: 'Elige un plan para seguir entrenando con FitZone.',
          actions: <Widget>[
            _PrimaryButton(label: 'Elegir un plan', onTap: widget.onChoosePlan),
            const SizedBox(height: 12),
            _SecondaryButton(label: 'Cerrar sesión', onTap: widget.onLogout),
          ],
        );
      case SubscriptionStatus.none:
        return _buildMessage(
          title: 'Aún no tienes un plan activo',
          message: 'Elige un plan para empezar a entrenar.',
          actions: <Widget>[
            _PrimaryButton(label: 'Elegir un plan', onTap: widget.onChoosePlan),
            const SizedBox(height: 12),
            _SecondaryButton(label: 'Cerrar sesión', onTap: widget.onLogout),
          ],
        );
    }
  }

  Widget _buildMessage({
    required String title,
    required String message,
    required List<Widget> actions,
    bool success = false,
    bool showDots = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: _PulseFigure(
            success: success,
            pulsing: _status == SubscriptionStatus.pending,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.display(
            size: 26,
            weight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 14,
            color: AppColors.whiteA(0.55),
            height: 1.6,
          ),
        ),
        if (showDots) ...<Widget>[
          const SizedBox(height: 20),
          const Center(child: PulsingDots(dotSize: 6, gap: 6)),
        ],
        if (_error.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          ErrorBox(_error),
        ],
        const SizedBox(height: 28),
        ...actions,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

/// Círculo central con anillos que se expanden y un leve flote.
class _PulseFigure extends StatefulWidget {
  const _PulseFigure({required this.success, required this.pulsing});

  final bool success;
  final bool pulsing;

  @override
  State<_PulseFigure> createState() => _PulseFigureState();
}

class _PulseFigureState extends State<_PulseFigure>
    with TickerProviderStateMixin {
  late final AnimationController _rings;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rings.dispose();
    _float.dispose();
    super.dispose();
  }

  Widget _ring(int index) {
    return AnimatedBuilder(
      animation: _rings,
      builder: (BuildContext context, Widget? _) {
        final double phase = (_rings.value - index * 0.423) % 1.0;
        final double e = Curves.easeOut.transform(phase);
        return Opacity(
          opacity: 0.7 * (1 - e),
          child: Transform.scale(
            scale: 0.6 + 2.0 * e,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyanA(0.4)),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool success = widget.success;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          if (widget.pulsing) ...<Widget>[_ring(0), _ring(1)],
          AnimatedBuilder(
            animation: _float,
            builder: (BuildContext context, Widget? child) {
              final double dy = -4 * Curves.easeInOut.transform(_float.value);
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: TweenAnimationBuilder<double>(
              key: ValueKey<bool>(success),
              tween: Tween<double>(begin: success ? 0.8 : 1, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (BuildContext context, double scale, Widget? child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: success
                        ? const <Color>[Color(0xFF34D399), Color(0xFF10B981)]
                        : <Color>[
                            AppColors.cyanA(0.22),
                            AppColors.tealA(0.12),
                          ],
                  ),
                  border: success
                      ? null
                      : Border.all(color: AppColors.cyanA(0.45), width: 1.5),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: success
                          ? const Color.fromRGBO(52, 211, 153, 0.35)
                          : AppColors.cyanA(0.22),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: Icon(
                  success
                      ? Icons.check_rounded
                      : Icons.fitness_center_rounded,
                  size: success ? 52 : 40,
                  color: success ? Colors.black : AppColors.cyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: <Color>[AppColors.cyan, AppColors.teal],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.cyanA(0.25),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 15.2,
            weight: FontWeight.w600,
            color: const Color(0xFF0A0A0A),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.whiteA(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.whiteA(0.14)),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: onTap == null ? AppColors.whiteA(0.4) : Colors.white,
          ),
        ),
      ),
    );
  }
}