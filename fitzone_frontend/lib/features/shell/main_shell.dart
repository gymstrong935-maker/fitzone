import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import '../achievements/achievements_screen.dart';
import '../community/community_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../plan/plan_screen.dart';
import '../stats/stats_screen.dart';
import 'pages/coming_soon_page.dart';
import 'pages/workout_placeholder_screen.dart';
import 'widgets/fz_bottom_nav.dart';

/// Pestañas principales de la aplicación.
const List<String> kMainTabs = <String>[
  'home',
  'stats',
  'plan',
  'settings',
];

/// Pantallas secundarias que se muestran sin la barra inferior.
const List<String> kSubScreens = <String>[
  'nutrition',
  'history',
  'achievements',
  'community',
];

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.userProfile,
  });

  final UserProfile userProfile;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _active = 'home';
  String _prev = 'home';

  bool _workoutActive = false;

  /// Progreso semanal:
  ///
  /// 0 = lunes
  /// 1 = martes
  /// 2 = miércoles
  /// 3 = jueves
  /// 4 = viernes
  /// 5 = sábado
  /// 6 = domingo
  ///
  /// true = entrenamiento completado.
  List<bool> _weekProgress = List<bool>.filled(
    7,
    false,
  );

  // ===========================================================================
  // NAVEGACIÓN
  // ===========================================================================

  void _navigate(String screen) {
    if (screen == _active) {
      return;
    }

    setState(() {
      _prev = _active;
      _active = screen;
    });
  }

  // ===========================================================================
  // ENTRENAMIENTO
  // ===========================================================================

  void _startWorkout() {
    setState(() {
      _workoutActive = true;
    });
  }

  void _cancelWorkout() {
    setState(() {
      _workoutActive = false;
    });
  }

  void _completeWorkout() {
    final int todayIndex = DateTime.now().weekday - 1;

    setState(() {
      _weekProgress = List<bool>.of(_weekProgress)
        ..[todayIndex] = true;

      _workoutActive = false;

      _prev = _active;
      _active = 'home';
    });
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // Si hay un entrenamiento activo, ocultamos completamente la navegación
    // principal y mostramos la pantalla del entrenamiento.
    // -------------------------------------------------------------------------
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
          // -------------------------------------------------------------------
          // Fondo ambiental
          // -------------------------------------------------------------------
          const Positioned.fill(
            child: AmbientBackground(),
          ),

          // -------------------------------------------------------------------
          // Pantalla actual
          // -------------------------------------------------------------------
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 280,
              ),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: _buildTransition,
              child: _buildScreen(),
            ),
          ),

          // -------------------------------------------------------------------
          // Barra de navegación inferior
          // -------------------------------------------------------------------
          //
          // Solo aparece en:
          //
          // Inicio
          // Estadísticas
          // Mi Plan
          // Ajustes
          //
          // Las pantallas secundarias no la muestran.
          // -------------------------------------------------------------------
          if (kMainTabs.contains(_active))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FzBottomNav(
                activeTab: _active,
                onTabChange: _navigate,
              ),
            ),

          // -------------------------------------------------------------------
          // Línea brillante superior
          // -------------------------------------------------------------------
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

  // ===========================================================================
  // CONSTRUCCIÓN DE PANTALLAS
  // ===========================================================================

  Widget _buildScreen() {
    final ValueKey<String> key = ValueKey<String>(
      _active,
    );

    void backHome() {
      _navigate('home');
    }

    switch (_active) {
      // =======================================================================
      // INICIO
      // =======================================================================

      case 'home':
        return HomeScreen(
          key: key,
          userProfile: widget.userProfile,
          weekProgress: _weekProgress,
          onNavigate: _navigate,
          onStartWorkout: _startWorkout,
        );

      // =======================================================================
      // ESTADÍSTICAS
      // =======================================================================

      case 'stats':
        return StatsScreen(
          key: key,
        );

      // =======================================================================
      // MI PLAN
      // =======================================================================

      case 'plan':
        return PlanScreen(
          key: key,
          weekProgress: _weekProgress,
          onStartWorkout: _startWorkout,
        );

      // =======================================================================
      // AJUSTES
      // =======================================================================

      case 'settings':
        return ComingSoonPage(
          key: key,
          title: 'Ajustes',
          icon: Icons.settings_rounded,
        );

      // =======================================================================
      // NUTRICIÓN
      // =======================================================================

      case 'nutrition':
        return NutritionScreen(
          key: key,
          onBack: backHome,
        );

      // =======================================================================
      // HISTORIAL
      // =======================================================================

      case 'history':
        return HistoryScreen(
          key: key,
          onBack: backHome,
        );

      // =======================================================================
      // LOGROS
      // =======================================================================

      case 'achievements':
        return AchievementsScreen(
          key: key,
          onBack: backHome,
        );

      // =======================================================================
      // COMUNIDAD
      // =======================================================================

      case 'community':
        return CommunityScreen(
          key: key,
          onBack: backHome,
        );

      // =======================================================================
      // FALLBACK
      // =======================================================================

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

  // ===========================================================================
  // TRANSICIONES
  // ===========================================================================

  Widget _buildTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final Key? childKey = child.key;

    final String id =
        childKey is ValueKey<String> ? childKey.value : '';

    final bool incoming = id == _active;

    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (
          BuildContext context,
          Widget? c,
        ) {
          final double inverse = 1 - animation.value;

          Offset offset;
          double scale = 1;

          // -------------------------------------------------------------------
          // Pantallas secundarias
          // -------------------------------------------------------------------

          if (kSubScreens.contains(id)) {
            offset = Offset(
              0,
              inverse * 40,
            );

            scale = 0.98 + (0.02 * animation.value);
          }

          // -------------------------------------------------------------------
          // Pantallas principales
          // -------------------------------------------------------------------

          else {
            final String other =
                incoming ? _prev : _active;

            // ---------------------------------------------------------------
            // Entrada/salida entre una pantalla principal y secundaria.
            // ---------------------------------------------------------------

            if (kSubScreens.contains(other) || other == id) {
              offset = Offset(
                0,
                (incoming ? 1 : -1) * 10 * inverse,
              );
            }

            // ---------------------------------------------------------------
            // Movimiento lateral entre pestañas principales.
            // ---------------------------------------------------------------

            else {
              final int currentIndex =
                  kMainTabs.indexOf(_active);

              final int previousIndex =
                  kMainTabs.indexOf(_prev);

              final int direction =
                  currentIndex > previousIndex ? 1 : -1;

              offset = Offset(
                (incoming ? direction : -direction) *
                    30 *
                    inverse,
                0,
              );
            }
          }

          return Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: scale,
              child: c,
            ),
          );
        },
      ),
    );
  }
}