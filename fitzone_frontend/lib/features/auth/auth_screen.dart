import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import 'models/auth_models.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_glass_card.dart';
import 'widgets/auth_logo.dart';
import 'widgets/auth_mode_tabs.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/fancy_input.dart';
import 'widgets/social_auth_section.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    this.onBack,
  });

  /// Inicia sesión. Debe devolver la acción a ejecutar cuando termine la
  /// animación de éxito (normalmente: navegar a la siguiente pantalla).
  /// Lanza [ApiException] si algo sale mal.
  final Future<VoidCallback> Function(String email, String password) onLogin;

  final Future<VoidCallback> Function(
    String name,
    String email,
    String password,
  ) onRegister;

  final Future<void> Function(String email) onForgotPassword;
  final VoidCallback? onBack;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shake;
  Timer? _pending;

  AuthMode _mode = AuthMode.login;
  int _direction = 1;
  String _error = '';
  bool _loading = false;
  bool _success = false;
  bool _showPassword = false;

  bool get _busy => _loading || _success;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    Animatable<double> step(double from, double to) =>
        Tween<double>(begin: from, end: to)
            .chain(CurveTween(curve: Curves.easeInOut));

    _shake = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: step(0, -7), weight: 18),
      TweenSequenceItem<double>(tween: step(-7, 7), weight: 18),
      TweenSequenceItem<double>(tween: step(7, -4), weight: 18),
      TweenSequenceItem<double>(tween: step(-4, 4), weight: 18),
      TweenSequenceItem<double>(tween: step(4, 0), weight: 28),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _pending?.cancel();
    _shakeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  void _switchMode(AuthMode next, int direction) {
    if (_busy) return;
    setState(() {
      _direction = direction;
      _mode = next;
      _error = '';
    });
  }

  void _showError(String message) {
    setState(() => _error = message);
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final AuthMode mode = _mode;
    final String email = _emailCtrl.text.trim();
    final String password = _passCtrl.text;
    final String name = _nameCtrl.text.trim();

    if (email.isEmpty || (mode != AuthMode.forgot && password.isEmpty)) {
      _showError('Por favor completa todos los campos');
      return;
    }
    if (mode == AuthMode.register && name.isEmpty) {
      _showError('Por favor ingresa tu nombre');
      return;
    }
    if (mode == AuthMode.register && name.length < 2) {
      _showError('El nombre debe tener al menos 2 caracteres');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showError('Ingresa un email válido');
      return;
    }
    if (mode == AuthMode.register && password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    VoidCallback? proceed;
    try {
      switch (mode) {
        case AuthMode.login:
          proceed = await widget.onLogin(email, password);
        case AuthMode.register:
          proceed = await widget.onRegister(name, email, password);
        case AuthMode.forgot:
          await widget.onForgotPassword(email);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Ocurrió un error inesperado. Inténtalo de nuevo.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });

    if (mode == AuthMode.forgot) {
      // Recuperar contraseña: confirma y vuelve a "Ingresar".
      _pending = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _success = false;
          _direction = -1;
          _mode = AuthMode.login;
        });
      });
      return;
    }

    _pending = Timer(const Duration(milliseconds: 700), () {
      if (mounted) proceed?.call();
    });
  }

  void _handleSocial(String provider) {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _showError('El inicio de sesión con $provider estará disponible pronto');
  }

  String get _submitLabel {
    switch (_mode) {
      case AuthMode.login:
        return 'Iniciar Sesión';
      case AuthMode.register:
        return 'Crear Cuenta';
      case AuthMode.forgot:
        return 'Enviar Instrucciones';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: AuthBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
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
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ShimmerTopBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
          child: _buildBrand(),
        ),
        const SizedBox(height: 32),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              duration: const Duration(milliseconds: 500),
              offsetY: 30,
              child: _buildCard(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Logo + eslogan ────────────────────────────────────────────────────────
  Widget _buildBrand() {
    return Column(
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
            size: 13.12,
            color: AppColors.whiteA(0.42),
            letterSpacing: 0.52,
          ),
        ),
      ],
    );
  }

  // ── Tarjeta ───────────────────────────────────────────────────────────────
  Widget _buildCard() {
    final bool isForgot = _mode == AuthMode.forgot;

    return AuthGlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!isForgot) ...<Widget>[
            AuthModeTabs(
              mode: _mode,
              onChanged: (AuthMode m) =>
                  _switchMode(m, m == AuthMode.register ? 1 : -1),
            ),
            const SizedBox(height: 24),
          ] else ...<Widget>[
            Text('Recuperar contraseña', style: AppText.display(size: 20)),
            const SizedBox(height: 4),
            Text(
              'Te enviaremos las instrucciones por email',
              style: AppText.body(size: 13.12, color: AppColors.whiteA(0.45)),
            ),
            const SizedBox(height: 20),
          ],
          _buildFormArea(),
          if (!isForgot)
            SocialAuthSection(enabled: !_busy, onPressed: _handleSocial),
          const SizedBox(height: 20),
          _buildBottomLink(),
        ],
      ),
    );
  }

  /// Formulario con transición lateral entre modos y sacudida al haber error.
  Widget _buildFormArea() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(offset: Offset(_shake.value, 0), child: child);
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          layoutBuilder: (Widget? current, List<Widget> previous) {
            return Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[...previous, if (current != null) current],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            final bool incoming = child.key == ValueKey<AuthMode>(_mode);
            final double dx = (incoming ? _direction : -_direction) * 18.0;
            return FadeTransition(
              opacity: animation,
              child: AnimatedBuilder(
                animation: animation,
                child: child,
                builder: (BuildContext context, Widget? c) {
                  return Transform.translate(
                    offset: Offset((1 - animation.value) * dx, 0),
                    child: c,
                  );
                },
              ),
            );
          },
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final bool isRegister = _mode == AuthMode.register;
    final bool isForgot = _mode == AuthMode.forgot;

    return Column(
      key: ValueKey<AuthMode>(_mode),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (isRegister) ...<Widget>[
          FancyInput(
            icon: Icons.person_outline_rounded,
            hint: 'Tu nombre completo',
            controller: _nameCtrl,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.name],
          ),
          const SizedBox(height: 12),
        ],
        FancyInput(
          icon: Icons.mail_outline_rounded,
          hint: 'tu@email.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: isForgot ? TextInputAction.done : TextInputAction.next,
          autofillHints: const <String>[AutofillHints.email],
          onSubmitted: isForgot ? (_) => _submit() : null,
        ),
        if (!isForgot) ...<Widget>[
          const SizedBox(height: 12),
          FancyInput(
            icon: Icons.lock_outline_rounded,
            hint: '••••••••',
            controller: _passCtrl,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            autofillHints: <String>[
              isRegister ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onSubmitted: (_) => _submit(),
            trailing: TextFieldTapRegion(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 17,
                    color: AppColors.whiteA(0.35),
                  ),
                ),
              ),
            ),
          ),
        ],
        _buildErrorBox(),
        const SizedBox(height: 12),
        AuthSubmitButton(
          label: _submitLabel,
          successLabel: isForgot ? '¡Enviado!' : '¡Bienvenido!',
          loading: _loading,
          success: _success,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildErrorBox() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _error.isEmpty
            ? const SizedBox(key: ValueKey<String>('no-error'), width: double.infinity)
            : Padding(
                key: ValueKey<String>(_error),
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(239, 68, 68, 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromRGBO(239, 68, 68, 0.22),
                    ),
                  ),
                  child: Text(
                    _error,
                    style: AppText.body(
                      size: 12,
                      color: const Color(0xFFF87171),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBottomLink() {
    switch (_mode) {
      case AuthMode.login:
        return _LinkButton(
          label: '¿Olvidaste tu contraseña?',
          color: AppColors.cyanA(0.75),
          onTap: () => _switchMode(AuthMode.forgot, 1),
        );
      case AuthMode.forgot:
        return _LinkButton(
          label: '← Volver al inicio',
          color: AppColors.cyan,
          onTap: () => _switchMode(AuthMode.login, -1),
        );
      case AuthMode.register:
        return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas pequeñas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (BuildContext context, double v, Widget? child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(-10 * (1 - v), 0), child: child),
        );
      },
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
                size: 20,
                color: AppColors.whiteA(0.45),
              ),
              const SizedBox(width: 4),
              Text(
                'Volver',
                style: AppText.body(size: 13.6, color: AppColors.whiteA(0.45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Text(label, style: AppText.body(size: 12.8, color: color)),
        ),
      ),
    );
  }
}