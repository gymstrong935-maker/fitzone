import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/sub_screen_frame.dart';
import '../home/widgets/home_card.dart';
import '../onboarding/data/experience_levels_data.dart';
import '../onboarding/data/goals_data.dart';
import '../onboarding/models/experience_level.dart';
import '../onboarding/models/goal.dart';
import '../onboarding/models/onboarding_data.dart';
import '../onboarding/models/trainer.dart';
import 'widgets/fz_switch.dart';
import 'widgets/settings_sheets.dart';

const List<String> _months = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _goalLabel(Goal? goal) {
  if (goal == null) return '—';
  for (final GoalOption option in kGoals) {
    if (option.id == goal) return option.title;
  }
  return goal.apiValue;
}

String _levelLabel(ExperienceLevel? level) {
  if (level == null) return '—';
  for (final ExperienceOption option in kExperienceLevels) {
    if (option.id == level) return option.title;
  }
  return level.apiValue;
}

/// "3 de octubre de 2026"
String _formatMemberSince(DateTime d) {
  return '${d.day} de ${_months[d.month - 1]} de ${d.year}';
}

/// Pantalla "Ajustes" (pestaña de la barra inferior; en el diseño se titula
/// "Configuración").
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.isLight,
    required this.onThemeToggle,
    required this.onBack,
    required this.onProfileChanged,
    required this.onRename,
    required this.onOpenNotifications,
    required this.onLogout,
  });

  final UserProfile userProfile;

  /// `true` = tema claro activo.
  final bool isLight;
  final VoidCallback onThemeToggle;
  final VoidCallback onBack;

  /// Cambios locales (objetivo o entrenador).
  final ValueChanged<UserProfile> onProfileChanged;

  /// Guarda el nombre en el servidor. Lanza [ApiException] si falla.
  final Future<void> Function(String name) onRename;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLogout;

  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _yellow400 = Color(0xFFFACC15);

  OnboardingData get _data => userProfile.onboardingData;

  // ── Acciones ──────────────────────────────────────────────────────────────

  void _toast(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppText.body(size: 14, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          backgroundColor: const Color(0xFF111111),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.whiteA(0.12)),
          ),
        ),
      );
  }

  Future<void> _editProfile(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? name = await showEditProfileSheet(
      context,
      name: userProfile.name,
      email: userProfile.email,
    );
    if (name == null || name == userProfile.name) return;

    try {
      await onRename(name);
      _toast(messenger, 'Perfil actualizado');
    } on ApiException catch (e) {
      _toast(messenger, e.message);
    } catch (_) {
      _toast(messenger, 'No se pudo actualizar el perfil');
    }
  }

  Future<void> _changeGoal(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Goal? goal = await showGoalSheet(context, current: _data.goal);
    if (goal == null || goal == _data.goal) return;
    onProfileChanged(
      userProfile.copyWith(onboardingData: _data.copyWith(goal: goal)),
    );
    _toast(messenger, 'Objetivo actualizado');
  }

  Future<void> _changeTrainer(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Trainer? trainer =
        await showTrainerSheet(context, current: _data.trainer);
    if (trainer == null || trainer.id == _data.trainer?.id) return;
    onProfileChanged(
      userProfile.copyWith(onboardingData: _data.copyWith(trainer: trainer)),
    );
    _toast(messenger, 'Entrenador actualizado');
  }

  Future<void> _logout(BuildContext context) async {
    final bool? confirmed = await showLogoutDialog(context);
    if (confirmed == true) onLogout();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Trainer? trainer = _data.trainer;

    return SubScreenFrame(
      title: 'Configuración',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _animated(0, _buildProfileCard(context)),
          const SizedBox(height: 16),
          _animated(50, _buildPreferencesCard(context, trainer)),
          const SizedBox(height: 16),
          _animated(100, _buildInfoCard(trainer)),
          const SizedBox(height: 16),
          _animated(150, _buildLogoutButton(context)),
        ],
      ),
    );
  }

  Widget _animated(int delayMs, Widget child) {
    return FadeSlideIn(
      delay: Duration(milliseconds: delayMs),
      duration: const Duration(milliseconds: 400),
      offsetY: 10,
      child: child,
    );
  }

  // ── Perfil ────────────────────────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context) {
    final String trimmed = userProfile.name.trim();
    final String initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.cyan, AppColors.teal],
                  ),
                ),
                child: Text(
                  initial,
                  style: AppText.body(
                    size: 24,
                    weight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.333,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      userProfile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userProfile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 12,
                        color: AppColors.whiteA(0.45),
                        height: 1.333,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _editProfile(context),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.whiteA(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.whiteA(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Editar Perfil',
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preferencias ──────────────────────────────────────────────────────────
  Widget _buildPreferencesCard(BuildContext context, Trainer? trainer) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle('Preferencias'),
          const SizedBox(height: 16),
          _SettingRow(
            icon: isLight ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            iconColor: isLight ? _yellow400 : _cyan400,
            label: 'Modo ${isLight ? 'Claro' : 'Oscuro'}',
            trailing: FzSwitch(
              value: !isLight,
              onChanged: (_) => onThemeToggle(),
            ),
          ),
          _SettingRow(
            icon: Icons.track_changes_rounded,
            iconColor: _cyan400,
            label: 'Cambiar Objetivo',
            onTap: () => _changeGoal(context),
          ),
          if (trainer != null)
            _SettingRow(
              icon: Icons.settings_outlined,
              iconColor: _cyan400,
              label: 'Cambiar Entrenador',
              onTap: () => _changeTrainer(context),
            ),
          _SettingRow(
            icon: Icons.notifications_none_rounded,
            iconColor: _cyan400,
            label: 'Notificaciones',
            onTap: onOpenNotifications,
          ),
        ],
      ),
    );
  }

  // ── Información ───────────────────────────────────────────────────────────
  Widget _buildInfoCard(Trainer? trainer) {
    final List<(String, String)> rows = <(String, String)>[
      ('Objetivo', _goalLabel(_data.goal)),
      ('Nivel', _levelLabel(_data.experienceLevel)),
      if (trainer != null) ('Entrenador', trainer.name),
      ('Miembro desde', _formatMemberSince(userProfile.createdAt)),
    ];

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle('Información'),
          const SizedBox(height: 16),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  rows[i].$1,
                  style: AppText.body(
                    size: 14,
                    color: AppColors.whiteA(0.45),
                    height: 1.43,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.end,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.whiteA(0.85),
                      height: 1.43,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Cerrar sesión ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _logout(context),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(239, 68, 68, 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.20)),
          ),
          child: Text(
            'Cerrar Sesión',
            style: AppText.body(
              size: 14,
              weight: FontWeight.w600,
              color: const Color(0xFFF87171),
              height: 1.43,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: AppText.display(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.whiteA(0.60),
        letterSpacing: 0.35,
        height: 1.43,
      ),
    );
  }
}

/// Fila de preferencias: ícono + texto a la izquierda y, a la derecha, un
/// control o una flecha. Lleva una línea tenue debajo.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  /// Control de la derecha; si es `null` se muestra una flecha.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.whiteA(0.07))),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                color: Colors.white,
                height: 1.43,
              ),
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.whiteA(0.30),
              ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: row,
        ),
      ),
    );
  }
}