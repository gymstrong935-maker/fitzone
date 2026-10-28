import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../notifications/notifications_controller.dart';
import '../notifications/widgets/notification_bell.dart';
import '../onboarding/models/onboarding_data.dart';
import 'data/home_data.dart';
import 'widgets/assistant_banner.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/stat_pill.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/trainer_card.dart';
import 'widgets/weekly_progress_card.dart';
import '../workout/data/routines_data.dart';
import '../plan/data/plan_generator.dart';

/// Pantalla "Inicio".
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userProfile,
    required this.weekProgress,
    required this.notifications,
    required this.onNavigate,
    required this.onStartWorkout,
    required this.onOpenNotifications,
    required this.onOpenAssistant,
    required this.onOpenAppointments,
    required this.plan,
    required this.sessionsThisWeek,
    required this.averageMinutes,
    required this.energyToday,
  });

  final UserProfile userProfile;

  /// 7 valores (lunes a domingo): `true` = día completado.
  final List<bool> weekProgress;

  /// Notificaciones del usuario (para el globito de la campana).
  final NotificationsController notifications;

  /// Navega a otra pantalla por id ("stats", "history", "nutrition", ...).
  final ValueChanged<String> onNavigate;
  final VoidCallback onStartWorkout;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenAssistant;
  final VoidCallback onOpenAppointments;
  /// Plan semanal generado con los datos del usuario.
  final TrainingPlan plan;

  /// Entrenamientos reales de esta semana.
  final int sessionsThisWeek;

  /// Minutos promedio por sesión real (`null` si todavía no hay ninguna).
  final int? averageMinutes;

  /// Energía de hoy según la última sesión de hoy (`null` si no se entrenó).
  final int? energyToday;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final String _greeting;
  late final String _quote;

  @override
  void initState() {
    super.initState();
    final int hour = DateTime.now().hour;
    _greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';
    _quote = kHomeQuotes[math.Random().nextInt(kHomeQuotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingData data = widget.userProfile.onboardingData;
    final habits = data.trainingHabits;
    final trainer = data.trainer;

    // Indicadores en tiempo real: salen de los entrenamientos guardados. Solo
    // si aún no hay datos reales se usa lo que la persona declaró al inicio.
    final int workoutsThisWeek = widget.sessionsThisWeek;
    final int? realMinutes = widget.averageMinutes;
    final int? realEnergy = widget.energyToday;
    final int minutes = realMinutes ?? habits.duration;
    final int energy =
        realEnergy ?? data.personalInfo.psychologicalCondition.energy;
    final String minutesSub = realMinutes != null ? 'por sesión' : 'planificados';
    final String energySub = realEnergy != null ? 'hoy' : 'hoy (est.)';
    final int weeklyGoal = habits.frequency;
    final TodayWorkout workout = widget.plan.todayWorkout(DateTime.now());
    final double bottomPadding = 96 + MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HomeHeader(
            greeting: _greeting,
            name: widget.userProfile.name,
            quote: _quote,
            trailing: ListenableBuilder(
              listenable: widget.notifications,
              builder: (BuildContext context, Widget? _) {
                return NotificationBell(
                  unread: widget.notifications.unreadCount,
                  onTap: widget.onOpenNotifications,
                );
              },
            ),
            pills: <Widget>[
              StatPill(
                icon: Icons.local_fire_department_outlined,
                value: '$workoutsThisWeek/$weeklyGoal esta semana',
                color: AppColors.orange,
              ),
              StatPill(
                icon: Icons.monitor_heart_outlined,
                value: '$minutes min/sesión',
                color: AppColors.cyanLight,
              ),
              StatPill(
                icon: Icons.favorite_border_rounded,
                value: 'Energía $energy/10',
                color: AppColors.pink,
              ),
            ],
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // ── Rutina de hoy ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      duration: const Duration(milliseconds: 400),
                      offsetY: 14,
                      child: TodayWorkoutCard(
                        workout: workout,
                        onStart: widget.onStartWorkout,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Progreso semanal ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 400),
                      offsetY: 14,
                      child: WeeklyProgressCard(
                        weekProgress: widget.weekProgress,
                        weeklyGoal: weeklyGoal,
                        onSeeMore: () => widget.onNavigate('stats'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Estadísticas rápidas ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      duration: const Duration(milliseconds: 400),
                      offsetY: 14,
                      child: QuickStatsRow(
                        sessions: workoutsThisWeek,
                        minutes: minutes,
                        energy: energy,
                        minutesSub: minutesSub,
                        energySub: energySub,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Accesos rápidos ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      duration: const Duration(milliseconds: 400),
                      offsetY: 14,
                      child: QuickActionsSection(onNavigate: widget.onNavigate),
                    ),
                    const SizedBox(height: 16),

                    // ── Asistente con IA ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 210),
                      duration: const Duration(milliseconds: 400),
                      offsetY: 14,
                      child: AssistantBanner(onTap: widget.onOpenAssistant),
                    ),

                    // ── Tu entrenador (solo si eligió uno) ──
                    if (trainer != null) ...<Widget>[
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        duration: const Duration(milliseconds: 400),
                        offsetY: 14,
                        child: TrainerCard(
                          trainer: trainer,
                          onSchedule: widget.onOpenAppointments,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}