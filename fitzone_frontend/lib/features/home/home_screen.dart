import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/user_profile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../notifications/notifications_controller.dart';
import '../notifications/widgets/notification_bell.dart';
import '../onboarding/models/onboarding_data.dart';
import 'data/home_data.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/stat_pill.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/trainer_card.dart';
import 'widgets/weekly_progress_card.dart';

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
    final int energy = data.personalInfo.psychologicalCondition.energy;
    final trainer = data.trainer;

    final int workoutsThisWeek = widget.weekProgress.where((bool d) => d).length;
    final int weeklyGoal = habits.frequency;
    final TodayWorkout workout = todayWorkoutFor(data.experienceLevel);
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
                color: const Color(0xFFFB923C),
              ),
              StatPill(
                icon: Icons.monitor_heart_outlined,
                value: '${habits.duration} min/sesión',
                color: AppColors.cyanLight,
              ),
              StatPill(
                icon: Icons.favorite_border_rounded,
                value: 'Energía $energy/10',
                color: const Color(0xFFF472B6),
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
                        minutes: habits.duration,
                        energy: energy,
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

                    // ── Tu entrenador (solo si eligió uno) ──
                    if (trainer != null) ...<Widget>[
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        duration: const Duration(milliseconds: 400),
                        offsetY: 14,
                        child: TrainerCard(trainer: trainer),
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