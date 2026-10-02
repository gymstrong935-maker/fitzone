import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import '../achievements/achievements_screen.dart';
import '../community/community_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../nutrition/nutrition_screen.dart';
import 'pages/coming_soon_page.dart';
import 'pages/workout_placeholder_screen.dart';
import 'widgets/fz_bottom_nav.dart';

/// Pestañas con barra de navegación inferior.
const List<String> kMainTabs = <String>['home', 'stats', 'plan', 'settings'];

/// Sub-pantallas que entran deslizándose desde abajo (sin barra inferior).
const List<String> kSubScreens = <String>[
  'nutrition',
  'history',
  'achievements',
  'community',
];

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.userProfile});

  final UserProfile userProfile;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _active = 'home';
  String _prev = 'home';
  bool _workoutActive = false;

  /// Lunes a domingo: `true` = día con entrenamiento completado.
  List<bool> _weekProgress = List<bool>.filled(7, false);

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

  void _completeWorkout() {
    final int index = DateTime.now().weekday - 1; // lunes = 0 ... domingo = 6
    setState(() {
      _weekProgress = List<bool>.of(_weekProgress)..[index] = true;
      _workoutActive = false;
      _prev = _active;
      _active = 'home';
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_workoutActive) {
      return WorkoutPlaceholderScreen(
        onComplete: _completeWorkout,
        onCancel: _cancelWorkout,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AmbientBackground()),

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

  Widget _buildScreen() {
    final ValueKey<String> key = ValueKey<String>(_active);
    void backHome() => _navigate('home');

    switch (_active) {
      case 'home':
        return HomeScreen(
          key: key,
          userProfile: widget.userProfile,
          weekProgress: _weekProgress,
          onNavigate: _navigate,
          onStartWorkout: _startWorkout,
        );
      case 'stats':
        return ComingSoonPage(
          key: key,
          title: 'Estadísticas',
          icon: Icons.bar_chart_rounded,
        );
      case 'plan':
        return ComingSoonPage(
          key: key,
          title: 'Mi Plan',
          icon: Icons.calendar_today_rounded,
        );
      case 'settings':
        return ComingSoonPage(
          key: key,
          title: 'Ajustes',
          icon: Icons.settings_rounded,
        );
      case 'nutrition':
        return NutritionScreen(key: key, onBack: backHome);
      case 'history':
        return HistoryScreen(key: key, onBack: backHome);
      case 'achievements':
        return AchievementsScreen(key: key, onBack: backHome);
      case 'community':
        return CommunityScreen(key: key, onBack: backHome);
      default:
        return HomeScreen(
          key: key,
          userProfile: widget.userProfile,
          weekProgress: _weekProgress,
          onNavigate: _navigate,
          onStartWorkout: _startWorkout,
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