import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_glass_card.dart';
import 'widgets/auth_logo.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/fancy_input.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  final String email;

  /// Verifica el código. Devuelve la acción a ejecutar tras la animación de
  /// éxito. Lanza [ApiException] si el código no sirve.
  final Future<VoidCallback> Function(String code) onVerify;

  final Future<void> Function() onResend;
  final VoidCallback onBack;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const int _cooldownSeconds = 30;

  final TextEditingController _codeCtrl = TextEditingController();

  Timer? _cooldownTimer;
  Timer? _advanceTimer;

  String _error = '';
  String _info = '';
  bool _loading = false;
  bool _success = false;
  bool _resending = false;
  int _cooldown = _cooldownSeconds;

  bool get _busy => _loading || _success;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _advanceTimer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final String code = _codeCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _info = '';
        _error = 'Ingresa el código de 6 dígitos';
      });
      return;
    }

    setState(() {
      _error = '';
      _info = '';
      _loading = true;
    });

    VoidCallback proceed;
    try {
      proceed = await widget.onVerify(code);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
    _advanceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) proceed();
    });
  }

  Future<void> _resend() async {
    if (_busy || _resending || _cooldown > 0) return;

    setState(() {
      _resending = true;
      _error = '';
      _info = '';
    });

    try {
      await widget.onResend();
      if (!mounted) return;
      setState(() => _info = 'Te enviamos un código nuevo a ${widget.email}');
      _startCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
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
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBack,
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
        ),
        const SizedBox(height: 24),
        const FadeSlideIn(
          duration: Duration(milliseconds: 500),
          offsetY: 22,
          child: Center(child: AuthLogo()),
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

  Widget _buildCard() {
    final bool canResend = _cooldown <= 0 && !_resending && !_busy;

    return AuthGlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Verifica tu correo', style: AppText.display(size: 20)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppText.body(
                size: 13.12,
                color: AppColors.whiteA(0.55),
                height: 1.5,
              ),
              children: <TextSpan>[
                const TextSpan(text: 'Enviamos un código de 6 dígitos a '),
                TextSpan(
                  text: widget.email,
                  style: AppText.body(
                    size: 13.12,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const TextSpan(text: '. Vence en 15 minutos.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FancyInput(
            icon: Icons.pin_outlined,
            hint: 'Código de 6 dígitos',
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ErrorBox(_error),
          ],
          if (_info.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _info,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12,
                color: const Color(0xFF34D399),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          AuthSubmitButton(
            label: 'Verificar cuenta',
            successLabel: '¡Verificada!',
            loading: _loading,
            success: _success,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canResend ? _resend : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  _resending
                      ? 'Enviando...'
                      : _cooldown > 0
                          ? 'Reenviar código en ${_cooldown}s'
                          : 'Reenviar código',
                  style: AppText.body(
                    size: 12.8,
                    color: canResend
                        ? AppColors.cyan
                        : AppColors.whiteA(0.35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}