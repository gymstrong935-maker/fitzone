import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/sub_screen_frame.dart';
import '../home/widgets/home_card.dart';
import '../onboarding/models/body_measurements.dart';
import '../onboarding/models/onboarding_data.dart';
import '../onboarding/models/personal_info.dart';
import '../onboarding/models/training_habits.dart';
import '../onboarding/steps/habits_step.dart';
import '../onboarding/steps/measurements_step.dart';
import '../onboarding/steps/personal_info_step.dart';

final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Reglas de la contraseña nueva. Devuelve el error o `null` si es válida.
String? validateNewPassword(String value, String confirmation) {
  if (value.length < 8) return 'Debe tener al menos 8 caracteres';
  if (value.length > 72) return 'No puede superar 72 caracteres';
  if (!RegExp(r'[a-z]').hasMatch(value) ||
      !RegExp(r'[A-Z]').hasMatch(value) ||
      !RegExp(r'[0-9]').hasMatch(value)) {
    return 'Debe incluir mayúscula, minúscula y número';
  }
  if (value != confirmation) return 'La confirmación no coincide';
  return null;
}

/// Editar perfil: cuenta (nombre y correo), contraseña con confirmación y todos
/// los datos de personalización que se pidieron al registrarse.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.data,
    required this.onSaveAccount,
    required this.onChangePassword,
    required this.onSaveData,
    required this.onBack,
  });

  final String name;
  final String email;
  final OnboardingData data;

  /// Guarda nombre y correo en el servidor. Lanza [ApiException] si falla.
  final Future<void> Function(String name, String email) onSaveAccount;

  /// Cambia la contraseña. Lanza [ApiException] si falla.
  final Future<void> Function(String? current, String next, String confirmation)
      onChangePassword;

  /// Guarda los datos personales. Lanza [ApiException] si falla.
  final Future<void> Function(OnboardingData data) onSaveData;
  final VoidCallback onBack;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.name);
  late final TextEditingController _email = TextEditingController(text: widget.email);
  final TextEditingController _current = TextEditingController();
  final TextEditingController _new = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  late OnboardingData _draft = widget.data;
  late String _savedName = widget.name;
  late String _savedEmail = widget.email;
  OnboardingData? _savedData;

  bool _showPasswords = false;
  String _accountMsg = '';
  bool _accountOk = false;
  bool _accountBusy = false;
  String _passMsg = '';
  bool _passOk = false;
  bool _passBusy = false;
  String _dataMsg = '';
  bool _dataOk = false;
  bool _dataBusy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ── Cuenta ────────────────────────────────────────────────────────────────
  String? get _accountError {
    final String name = _name.text.trim();
    final String email = _email.text.trim();
    if (name.length < 2) return 'Escribe tu nombre (mínimo 2 letras)';
    if (name.length > 60) return 'El nombre es demasiado largo';
    if (!_emailRegex.hasMatch(email)) return 'Escribe un correo válido';
    return null;
  }

  bool get _accountChanged =>
      _name.text.trim() != _savedName || _email.text.trim().toLowerCase() != _savedEmail;

  Future<void> _saveAccount() async {
    final String? error = _accountError;
    if (error != null) {
      setState(() {
        _accountMsg = error;
        _accountOk = false;
      });
      return;
    }
    setState(() {
      _accountBusy = true;
      _accountMsg = '';
    });
    try {
      final String name = _name.text.trim();
      final String email = _email.text.trim().toLowerCase();
      await widget.onSaveAccount(name, email);
      if (!mounted) return;
      setState(() {
        _savedName = name;
        _savedEmail = email;
        _accountOk = true;
        _accountMsg = 'Datos de la cuenta actualizados';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _accountOk = false;
        _accountMsg = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accountOk = false;
        _accountMsg = 'No se pudo guardar. Inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  // ── Contraseña ────────────────────────────────────────────────────────────
  Future<void> _savePassword() async {
    final String? error = validateNewPassword(_new.text, _confirm.text);
    if (error != null) {
      setState(() {
        _passMsg = error;
        _passOk = false;
      });
      return;
    }
    setState(() {
      _passBusy = true;
      _passMsg = '';
    });
    try {
      await widget.onChangePassword(
        _current.text.isEmpty ? null : _current.text,
        _new.text,
        _confirm.text,
      );
      if (!mounted) return;
      _current.clear();
      _new.clear();
      _confirm.clear();
      setState(() {
        _passOk = true;
        _passMsg = 'Contraseña actualizada';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _passOk = false;
        _passMsg = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _passOk = false;
        _passMsg = 'No se pudo cambiar la contraseña.';
      });
    } finally {
      if (mounted) setState(() => _passBusy = false);
    }
  }

  // ── Datos personales ──────────────────────────────────────────────────────
  List<String> get _missing => <String>[
        ..._draft.personalInfo.missing,
        ..._draft.bodyMeasurements.missing.map((String s) => 'circunferencia: $s'),
        ..._draft.trainingHabits.missing,
      ];

  /// `true` si intentó guardar con datos sin llenar: solo entonces se avisa.
  bool _saveAttempted = false;

  Future<void> _saveData() async {
    if (_missing.isNotEmpty) {
      setState(() => _saveAttempted = true);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _dataBusy = true;
      _dataMsg = '';
    });
    try {
      final OnboardingData data =
          _draft.copyWith(personalInfo: _draft.personalInfo.sanitized());
      await widget.onSaveData(data);
      if (!mounted) return;
      setState(() {
        _draft = data;
        _savedData = data;
        _dataOk = true;
        _dataMsg = 'Datos guardados. Tu plan se ajustó a tu nueva información.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _dataOk = false;
        _dataMsg = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dataOk = false;
        _dataMsg = 'No se pudieron guardar los datos. Inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _dataBusy = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final OnboardingData base = _savedData ?? widget.data;
    final bool dataChanged = !identical(_draft, base) && _draft != base;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SubScreenFrame(
        title: 'Editar perfil',
        subtitle: 'Tu cuenta, tu contraseña y tus datos personales',
        onBack: widget.onBack,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildAccount(),
              const SizedBox(height: 16),
              _buildPassword(),
              const SizedBox(height: 16),
              _buildData(dataChanged),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccount() {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionTitle('Cuenta'),
          const SizedBox(height: 14),
          _Field(
            label: 'Nombre',
            controller: _name,
            icon: Icons.person_outline_rounded,
            maxLength: 60,
            onChanged: (_) => setState(() => _accountMsg = ''),
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Correo electrónico',
            controller: _email,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _accountMsg = ''),
          ),
          if (_accountMsg.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _Message(_accountMsg, ok: _accountOk),
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Guardar cuenta',
            busy: _accountBusy,
            enabled: _accountChanged,
            onTap: _saveAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildPassword() {
    final String newPass = _new.text;
    final bool lenOk = newPass.length >= 8;
    final bool caseOk =
        RegExp(r'[a-z]').hasMatch(newPass) && RegExp(r'[A-Z]').hasMatch(newPass);
    final bool numOk = RegExp(r'[0-9]').hasMatch(newPass);
    final bool matchOk = newPass.isNotEmpty && newPass == _confirm.text;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionTitle('Contraseña'),
          const SizedBox(height: 6),
          Text(
            'Ingresas a FitZone con Google; esta contraseña es un respaldo de tu cuenta.',
            style: AppText.body(size: 12.5, color: AppColors.whiteA(0.45), height: 1.45),
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Contraseña actual (si ya tienes una)',
            controller: _current,
            icon: Icons.lock_outline_rounded,
            obscure: !_showPasswords,
            onChanged: (_) => setState(() => _passMsg = ''),
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Contraseña nueva',
            controller: _new,
            icon: Icons.lock_reset_rounded,
            obscure: !_showPasswords,
            onChanged: (_) => setState(() => _passMsg = ''),
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Confirmar contraseña nueva',
            controller: _confirm,
            icon: Icons.verified_user_outlined,
            obscure: !_showPasswords,
            onChanged: (_) => setState(() => _passMsg = ''),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showPasswords = !_showPasswords),
            child: Row(
              children: <Widget>[
                Icon(
                  _showPasswords
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.cyanText,
                ),
                const SizedBox(width: 6),
                Text(
                  _showPasswords ? 'Ocultar' : 'Mostrar contraseñas',
                  style: AppText.body(size: 12.5, color: AppColors.cyanText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              _Rule('8+ caracteres', lenOk),
              _Rule('Mayúscula y minúscula', caseOk),
              _Rule('Un número', numOk),
              _Rule('Coinciden', matchOk),
            ],
          ),
          if (_passMsg.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _Message(_passMsg, ok: _passOk),
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Cambiar contraseña',
            busy: _passBusy,
            enabled: newPass.isNotEmpty || _confirm.text.isNotEmpty,
            onTap: _savePassword,
          ),
        ],
      ),
    );
  }

  Widget _buildData(bool changed) {
    final List<String> missing = _missing;

    return HomeCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionTitle('Datos personales'),
          const SizedBox(height: 18),
          PersonalInfoStep(
            showLaterNote: false,
            showErrors: _saveAttempted,
            info: _draft.personalInfo,
            onChanged: (PersonalInfo v) => setState(() {
              _draft = _draft.copyWith(personalInfo: v);
              _dataMsg = '';
            }),
          ),
          const SizedBox(height: 28),
          MeasurementsStep(
            showLaterNote: false,
            showErrors: _saveAttempted,
            measurements: _draft.bodyMeasurements,
            onChanged: (BodyMeasurements v) => setState(() {
              _draft = _draft.copyWith(bodyMeasurements: v);
              _dataMsg = '';
            }),
          ),
          const SizedBox(height: 28),
          HabitsStep(
            showLaterNote: false,
            habits: _draft.trainingHabits,
            onChanged: (TrainingHabits v) => setState(() {
              _draft = _draft.copyWith(trainingHabits: v);
              _dataMsg = '';
            }),
          ),
          if (_saveAttempted && missing.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Antes de guardar completa: ${missing.join(', ')}',
              style: AppText.body(size: 12.5, color: AppColors.amber, height: 1.4),
            ),
          ],
          if (_dataMsg.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _Message(_dataMsg, ok: _dataOk),
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Guardar datos',
            busy: _dataBusy,
            enabled: changed,
            onTap: _saveData,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.display(
        size: 14,
        color: AppColors.whiteA(0.60),
        letterSpacing: 0.35,
        height: 1.43,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.whiteA(0.55)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.whiteA(0.12)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.whiteA(0.4)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  autocorrect: false,
                  enableSuggestions: !obscure,
                  inputFormatters: <TextInputFormatter>[
                    if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
                  ],
                  cursorColor: AppColors.cyanText,
                  onChanged: onChanged,
                  style: AppText.body(size: 15),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.text, this.ok);

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final Color color = ok ? AppColors.green : AppColors.whiteA(0.38);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(ok ? Icons.check_circle_rounded : Icons.circle_outlined, size: 14, color: color),
        const SizedBox(width: 5),
        Text(text, style: AppText.body(size: 12, color: color)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final Color color = ok ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppText.body(size: 12.8, color: color, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && !busy;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: active ? onTap : null,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: enabled
              ? const LinearGradient(colors: <Color>[AppColors.cyan, AppColors.teal])
              : null,
          color: enabled ? null : AppColors.whiteA(0.06),
          border: enabled ? null : Border.all(color: AppColors.whiteA(0.10)),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
              )
            : Text(
                label,
                style: AppText.body(
                  size: 14.5,
                  weight: FontWeight.w600,
                  color: enabled ? AppColors.onAccent : AppColors.whiteA(0.3),
                ),
              ),
      ),
    );
  }
}
