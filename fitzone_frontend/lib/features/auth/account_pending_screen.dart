import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/backend_models.dart';
import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import '../support/widgets/support_sheets.dart';

/// Pantalla de espera: el equipo de FitZone debe aprobar la cuenta nueva.
class AccountPendingScreen extends StatefulWidget {
  const AccountPendingScreen({
    super.key,
    required this.user,
    required this.refresh,
    required this.onApproved,
    required this.onLogout,
  });

  final BackendUser user;

  /// Vuelve a consultar el usuario en el servidor.
  final Future<BackendUser> Function() refresh;

  /// Se llama cuando la cuenta ya fue aprobada.
  final void Function(BackendUser user) onApproved;

  final VoidCallback onLogout;

  @override
  State<AccountPendingScreen> createState() => _AccountPendingScreenState();
}

class _AccountPendingScreenState extends State<AccountPendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rings;
  Timer? _poll;
  Timer? _advance;

  late BackendUser _user = widget.user;
  bool _checking = false;
  String _error = '';

  bool get _rejected => _user.estadoCuenta == 'rechazado';
  bool get _approved => _user.estadoCuenta == 'activo';

  @override
  void initState() {
    super.initState();
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _advance?.cancel();
    _rings.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || !mounted || _approved) return;
    setState(() => _checking = true);

    try {
      final BackendUser fresh = await widget.refresh();
      if (!mounted) return;
      setState(() {
        _user = fresh;
        _error = '';
      });

      if (fresh.estadoCuenta == 'activo') {
        _poll?.cancel();
        _advance ??= Timer(const Duration(milliseconds: 1500), () {
          if (mounted) widget.onApproved(fresh);
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _contactSupport() async {
    await showSupportRequestSheet(context, transcript: const <ChatTurn>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: EllipseGlow(
              color: _rejected
                  ? const Color.fromRGBO(239, 68, 68, 0.12)
                  : AppColors.cyanA(0.14),
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
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildBody(),
                ),
              ),
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: ShimmerTopBar()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final String title = _approved
        ? '¡Cuenta aprobada!'
        : _rejected
            ? 'No pudimos aprobar tu cuenta'
            : 'Tu cuenta está en revisión';

    final String message = _approved
        ? 'Todo listo. Te llevamos a continuar con tu registro.'
        : _rejected
            ? 'El equipo de FitZone revisó tu solicitud y por ahora no pudo aprobarla.'
            : 'Recibimos tu registro. El equipo de FitZone debe aprobar tu cuenta antes de que puedas continuar. Te avisaremos por correo y esta pantalla se actualiza sola.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(child: _buildHalo()),
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
          style: AppText.body(size: 14, color: AppColors.whiteA(0.55), height: 1.6),
        ),
        if (_rejected && _user.motivoRechazo.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(239, 68, 68, 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.22)),
            ),
            child: Text(
              'Motivo: ${_user.motivoRechazo}',
              style: AppText.body(
                size: 13.5,
                color: const Color(0xFFF87171),
                height: 1.5,
              ),
            ),
          ),
        ],
        if (!_rejected && !_approved) ...<Widget>[
          const SizedBox(height: 22),
          _buildSteps(),
        ],
        if (_error.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          ErrorBox(_error),
        ],
        const SizedBox(height: 28),
        if (!_approved) ...<Widget>[
          if (!_rejected) ...<Widget>[
            _Button(
              label: _checking ? 'Revisando...' : 'Actualizar estado',
              primary: true,
              onTap: _checking ? null : _check,
            ),
            const SizedBox(height: 12),
          ],
          _Button(
            label: 'Hablar con soporte',
            primary: _rejected,
            onTap: _contactSupport,
          ),
          const SizedBox(height: 12),
          _Button(label: 'Cerrar sesión', onTap: widget.onLogout),
        ],
      ],
    );
  }

  Widget _buildSteps() {
    Widget step(IconData icon, Color color, String text, {bool active = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppText.body(
                  size: 13.5,
                  weight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : AppColors.whiteA(0.60),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        children: <Widget>[
          step(Icons.check_circle_rounded, const Color(0xFF34D399), 'Registro y correo verificados'),
          step(Icons.hourglass_top_rounded, const Color(0xFFFBBF24), 'Aprobación del equipo de FitZone', active: true),
          step(Icons.radio_button_unchecked_rounded, AppColors.whiteA(0.30), 'Elige tu plan y configura tu perfil'),
        ],
      ),
    );
  }

  Widget _buildHalo() {
    final Color color = _approved
        ? const Color(0xFF34D399)
        : (_rejected ? const Color(0xFFF87171) : AppColors.cyan);
    final IconData icon = _approved
        ? Icons.check_rounded
        : (_rejected ? Icons.block_rounded : Icons.hourglass_top_rounded);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (!_rejected && !_approved)
            AnimatedBuilder(
              animation: _rings,
              builder: (BuildContext context, Widget? _) {
                final double e = Curves.easeOut.transform(_rings.value);
                return Opacity(
                  opacity: 0.6 * (1 - e),
                  child: Transform.scale(
                    scale: 0.6 + 2.0 * e,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withAlpha(110)),
                      ),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(36),
              border: Border.all(color: color.withAlpha(140), width: 1.5),
              boxShadow: <BoxShadow>[
                BoxShadow(color: color.withAlpha(60), blurRadius: 28),
              ],
            ),
            child: Icon(icon, size: 44, color: color),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap, this.primary = false});

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: primary ? 52 : 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: primary
              ? const LinearGradient(colors: <Color>[AppColors.cyan, AppColors.teal])
              : null,
          color: primary ? null : AppColors.whiteA(0.08),
          border: primary ? null : Border.all(color: AppColors.whiteA(0.14)),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: primary ? 15.2 : 14,
            weight: FontWeight.w600,
            color: primary
                ? const Color(0xFF0A0A0A)
                : (onTap == null ? AppColors.whiteA(0.4) : Colors.white),
          ),
        ),
      ),
    );
  }
}