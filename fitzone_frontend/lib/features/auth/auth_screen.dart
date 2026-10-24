import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_glass_card.dart';
import 'widgets/auth_logo.dart';

const String _googleSvg = r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#EA4335" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#4A90D9" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#FBBC05" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

/// Acceso a FitZone: ÚNICAMENTE con Google (sirve para registrarse y para entrar).
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onGoogleLogin,
    this.planName,
    this.onBack,
    this.notice,
  });

  /// Inicia sesión con Google. Devuelve la acción a ejecutar cuando termina la
  /// animación de éxito, o `null` si la persona cancela. Lanza [ApiException]
  /// si algo sale mal (por ejemplo, plan distinto al de su cuenta).
  final Future<VoidCallback?> Function() onGoogleLogin;

  /// Plan elegido. `null` = "Ya tengo cuenta" (entra con el plan de su cuenta).
  final String? planName;
  final VoidCallback? onBack;

  /// Aviso verde sobre el botón.
  final String? notice;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;
  bool _success = false;
  String _error = '';
  String _hint = '';

  Future<void> _google() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
      _hint = '';
    });

    try {
      final VoidCallback? next = await widget.onGoogleLogin();
      if (!mounted) return;

      if (next == null) {
        // La persona cerró el selector de cuentas (o Google lo canceló).
        setState(() {
          _loading = false;
          _hint = 'No se completó el inicio de sesión con Google. Si el selector '
              'de cuentas se cerró solo, inténtalo de nuevo.';
        });
        return;
      }

      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      next();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo iniciar sesión con Google. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AuthBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                          child: _buildContent(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: ShimmerTopBar()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final bool registering = widget.planName != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.onBack != null) ...<Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onTap: widget.onBack!),
          ),
          const SizedBox(height: 24),
        ],
        FadeSlideIn(
          duration: const Duration(milliseconds: 500),
          offsetY: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AuthLogo(),
              const SizedBox(height: 16),
              Text(
                'FitZone',
                style: AppText.display(size: 28.8, letterSpacing: -0.72, height: 1),
              ),
              const SizedBox(height: 6),
              Text(
                'Tu entrenador personal digital',
                style: AppText.body(
                  size: 13.1,
                  color: AppColors.whiteA(0.42),
                  letterSpacing: 0.52,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              duration: const Duration(milliseconds: 500),
              offsetY: 30,
              child: AuthGlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (widget.notice != null && widget.notice!.isNotEmpty) ...<Widget>[
                      _Notice(widget.notice!),
                      const SizedBox(height: 16),
                    ],
                    if (registering)
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cyanA(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.cyanA(0.25)),
                          ),
                          child: Text(
                            'PLAN ${widget.planName!.toUpperCase()}',
                            style: AppText.body(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: AppColors.cyanText,
                              letterSpacing: 0.92,
                            ),
                          ),
                        ),
                      ),
                    if (registering) const SizedBox(height: 14),
                    Text(
                      registering ? 'Crea tu cuenta' : 'Bienvenido de vuelta',
                      textAlign: TextAlign.center,
                      style: AppText.display(size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      registering
                          ? 'Regístrate o inicia sesión con tu cuenta de Google.'
                          : 'Entra con la cuenta de Google con la que te registraste.',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        size: 13.2,
                        color: AppColors.whiteA(0.5),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_error.isNotEmpty) ...<Widget>[
                      ErrorBox(_error),
                      const SizedBox(height: 14),
                    ] else if (_hint.isNotEmpty) ...<Widget>[
                      Text(
                        _hint,
                        textAlign: TextAlign.center,
                        style: AppText.body(size: 12.5, color: AppColors.amber, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _GoogleButton(
                      loading: _loading,
                      success: _success,
                      onTap: _google,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      registering
                          ? 'Si ya tienes cuenta, solo podrás entrar con el plan con el que te registraste.'
                          : 'Es la única forma de acceso a FitZone. No necesitas contraseña.',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        size: 11.8,
                        color: AppColors.whiteA(0.38),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatefulWidget {
  const _GoogleButton({
    required this.loading,
    required this.success,
    required this.onTap,
  });

  final bool loading;
  final bool success;
  final VoidCallback onTap;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.loading;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white, // botón oficial de Google: siempre blanco
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.whiteA(0.12)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.cyanA(0.18),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.success)
                const Icon(Icons.check_circle_rounded, size: 22, color: Color(0xFF16A34A))
              else if (widget.loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF0F172A)),
                )
              else
                SvgPicture.string(_googleSvg, width: 22, height: 22),
              const SizedBox(width: 12),
              Text(
                widget.success
                    ? '¡Listo!'
                    : widget.loading
                        ? 'Conectando con Google...'
                        : 'Continuar con Google',
                style: AppText.body(
                  size: 15.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(52, 211, 153, 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(52, 211, 153, 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppText.body(size: 12, color: AppColors.green, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.whiteA(0.5)),
            const SizedBox(width: 6),
            Text('Volver', style: AppText.body(size: 14, color: AppColors.whiteA(0.5))),
          ],
        ),
      ),
    );
  }
}
