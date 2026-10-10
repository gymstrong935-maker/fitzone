import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/services/app_services.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import '../achievements/achievements_screen.dart';
import '../community/community_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_controller.dart';
import '../notifications/notifications_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../plan/plan_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../workout/data/exercises_data.dart';
import '../workout/models/workout_log.dart';
import '../workout/workout_screen.dart';
import 'widgets/fz_bottom_nav.dart';

/// Pestañas con barra de navegación inferior.
const List<String> kMainTabs = <String>['home', 'stats', 'plan', 'settings'];

/// Sub-pantallas que entran deslizándose desde abajo (sin barra inferior).
const List<String> kSubScreens = <String>[
  'nutrition',
  'history',
  'achievements',
  'community',
  'notifications',
];

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.userProfile,
    required this.onLogout,
    required this.onRename,
    required this.onProfileChanged,
  });

  final UserProfile userProfile;

  /// Se llama cuando el usuario confirma "Cerrar Sesión".
  final VoidCallback onLogout;

  /// Guarda el nombre en el servidor. Lanza `ApiException` si falla.
  final Future<void> Function(String name) onRename;

  /// Avisa que cambió el objetivo o el entrenador (para guardarlo).
  final void Function(UserProfile previous, UserProfile next) onProfileChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _active = 'home';
  String _prev = 'home';
  bool _workoutActive = false;
  bool _isLight = false;

  /// Perfil editable (nombre, objetivo y entrenador se pueden cambiar en
  /// Ajustes).
  late UserProfile _profile = widget.userProfile;

  /// Notificaciones reales del servidor (se actualizan cada minuto).
  late final NotificationsController _notifications = NotificationsController(
    service: AppServices.instance.notifications,
    userId: widget.userProfile.id,
  );

  /// Lunes a domingo: `true` = día con entrenamiento completado.
  List<bool> _weekProgress = List<bool>.filled(7, false);

  /// Entrenamientos guardados (los usaremos cuando conectemos el historial).
  final List<WorkoutLog> _workoutLogs = <WorkoutLog>[];

  @override
  void initState() {
    super.initState();
    _notifications.start();
  }

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  void _navigate(String screen) {
    if (screen == _active) return;
    setState(() {
      _prev = _active;
      _active = screen;
    });
  }

  void _startWorkout() => setState(() => _workoutActive = true);

  void _cancelWorkout() => setState(() => _workoutActive = false);

  void _completeWorkout(WorkoutLog log) {
    final int index = DateTime.now().weekday - 1; // lunes = 0 ... domingo = 6
    _workoutLogs.add(log);
    setState(() {
      _weekProgress = List<bool>.of(_weekProgress)..[index] = true;
      _workoutActive = false;
      _prev = _active;
      _active = 'home';
    });
  }

  void _toggleTheme() => setState(() => _isLight = !_isLight);

  /// Objetivo o entrenador cambiados desde Ajustes.
  void _updateProfile(UserProfile profile) {
    final UserProfile previous = _profile;
    setState(() => _profile = profile);
    widget.onProfileChanged(previous, profile);
  }

  /// Nombre: primero el servidor; solo si responde bien se cambia en pantalla.
  Future<void> _rename(String name) async {
    await widget.onRename(name);
    if (!mounted) return;
    setState(() => _profile = _profile.copyWith(name: name));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_workoutActive) {
      return WorkoutScreen(
        exercises: kExercises,
        onComplete: _completeWorkout,
        onCancel: _cancelWorkout,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        color: _isLight ? const Color(0xFFF0F4F8) : Colors.black,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: AmbientBackground(isLight: _isLight)),

            // ── Contenido ──
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: _buildTransition,
                child: _buildScreen(),
              ),
            ),

            // ── Barra inferior (solo en las 4 pestañas) ──
            if (kMainTabs.contains(_active))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FzBottomNav(activeTab: _active, onTabChange: _navigate),
              ),

            // ── Línea brillante superior ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ShimmerTopBar(
                colors: _isLight
                    ? ShimmerTopBar.lightColors
                    : ShimmerTopBar.defaultColors,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen() {
    final ValueKey<String> key = ValueKey<String>(_active);
    void backHome() => _navigate('home');

    switch (_active) {
      case 'stats':
        return StatsScreen(key: key);
      case 'plan':
        return PlanScreen(
          key: key,
          weekProgress: _weekProgress,
          onStartWorkout: _startWorkout,
        );
      case 'settings':
        return SettingsScreen(
          key: key,
          userProfile: _profile,
          isLight: _isLight,
          onThemeToggle: _toggleTheme,
          onBack: backHome,
          onProfileChanged: _updateProfile,
          onRename: _rename,
          onOpenNotifications: () => _navigate('notifications'),
          onLogout: widget.onLogout,
        );
      case 'notifications':
        return NotificationsScreen(
          key: key,
          controller: _notifications,
          onBack: backHome,
        );
      case 'nutrition':
        return NutritionScreen(key: key, onBack: backHome);
      case 'history':
        return HistoryScreen(key: key, onBack: backHome);
      case 'achievements':
        return AchievementsScreen(key: key, onBack: backHome);
      case 'community':
        return CommunityScreen(key: key, onBack: backHome);
      case 'home':
      default:
        return HomeScreen(
          key: key,
          userProfile: _profile,
          weekProgress: _weekProgress,
          notifications: _notifications,
          onNavigate: _navigate,
          onStartWorkout: _startWorkout,
          onOpenNotifications: () => _navigate('notifications'),
        );
    }
  }

  /// Transiciones del diseño:
  /// - sub-pantallas: suben desde abajo con fade y un poco de escala;
  /// - entre pestañas: deslizamiento lateral según el orden de las pestañas;
  /// - pestaña <-> sub-pantalla: desplazamiento vertical corto.
  Widget _buildTransition(Widget child, Animation<double> animation) {
    final Key? childKey = child.key;
    final String id = childKey is ValueKey<String> ? childKey.value : '';
    final bool incoming = id == _active;

    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (BuildContext context, Widget? c) {
          final double inv = 1 - animation.value;
          Offset offset;
          double scale = 1;

          if (kSubScreens.contains(id)) {
            offset = Offset(0, inv * 40);
            scale = 0.98 + 0.02 * animation.value;
          } else {
            final String other = incoming ? _prev : _active;
            if (kSubScreens.contains(other) || other == id) {
              offset = Offset(0, (incoming ? 1 : -1) * 10 * inv);
            } else {
              final int dir =
                  kMainTabs.indexOf(_active) > kMainTabs.indexOf(_prev) ? 1 : -1;
              offset = Offset((incoming ? dir : -dir) * 30 * inv, 0);
            }
          }

          return Transform.translate(
            offset: offset,
            child: Transform.scale(scale: scale, child: c),
          );
        },
      ),
    );
  }
}