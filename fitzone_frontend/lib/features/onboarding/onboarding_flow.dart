import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/pressable_scale.dart';
import '../plan_selection/models/plan.dart';
import 'models/body_measurements.dart';
import 'models/experience_level.dart';
import 'models/goal.dart';
import 'models/onboarding_data.dart';
import 'models/onboarding_step.dart';
import 'models/personal_info.dart';
import 'models/trainer.dart';
import 'models/training_habits.dart';
import 'steps/experience_step.dart';
import 'steps/goals_step.dart';
import 'steps/habits_step.dart';
import 'steps/measurements_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/trainer_step.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/onboarding_progress_bar.dart';
import 'widgets/step_dots.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.planType,
    required this.onComplete,
    this.onExit,
  });

  final PlanId planType;
  final ValueChanged<OnboardingData> onComplete;

  /// Qué hacer al pulsar "atrás" en el primer paso (p. ej. volver a elegir plan).
  /// Si es `null`, el botón no aparece en el primer paso.
  final VoidCallback? onExit;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final List<OnboardingStep> _steps = stepsForPlan(widget.planType);
  final ScrollController _scroll = ScrollController();

  int _step = 0;
  int _direction = 1;
  OnboardingData _data = const OnboardingData();

  OnboardingStep get _current => _steps[_step];
  bool get _isLast => _step == _steps.length - 1;
  bool get _canGoBack => _step > 0 || widget.onExit != null;

  bool get _nextEnabled {
    switch (_current) {
      case OnboardingStep.trainer:
        return _data.trainer != null;
      case OnboardingStep.goals:
        return _data.goal != null;
      case OnboardingStep.experience:
        return _data.experienceLevel != null;
      case OnboardingStep.personalInfo:
        return _data.personalInfo.isComplete;
      case OnboardingStep.measurements:
        return _data.bodyMeasurements.isComplete;
      case OnboardingStep.habits:
        return _data.trainingHabits.isComplete;
    }
  }

  /// Qué falta por llenar en el paso actual (vacío si no falta nada).
  List<String> get _missing {
    switch (_current) {
      case OnboardingStep.trainer:
        return _data.trainer == null ? <String>['tu entrenador'] : const <String>[];
      case OnboardingStep.goals:
        return _data.goal == null ? <String>['tu objetivo'] : const <String>[];
      case OnboardingStep.experience:
        return _data.experienceLevel == null
            ? <String>['tu nivel de experiencia']
            : const <String>[];
      case OnboardingStep.personalInfo:
        return _data.personalInfo.missing;
      case OnboardingStep.measurements:
        return _data.bodyMeasurements.missing;
      case OnboardingStep.habits:
        return _data.trainingHabits.missing;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _resetScroll() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _goNext() {
    if (!_nextEnabled) return;
    FocusManager.instance.primaryFocus?.unfocus();

    // Aplica los mínimos de Información Personal antes de avanzar.
    final OnboardingData data = _data.copyWith(
      personalInfo: _data.personalInfo.sanitized(),
    );

    if (_isLast) {
      widget.onComplete(data);
      return;
    }
    setState(() {
      _data = data;
      _direction = 1;
      _step++;
    });
    _resetScroll();
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 0) {
      widget.onExit?.call();
      return;
    }
    setState(() {
      _direction = -1;
      _step--;
    });
    _resetScroll();
  }

  void _selectTrainer(Trainer trainer) {
    setState(() => _data = _data.copyWith(trainer: trainer));
  }

  void _updatePersonalInfo(PersonalInfo info) {
    setState(() => _data = _data.copyWith(personalInfo: info));
  }

  void _updateMeasurements(BodyMeasurements measurements) {
    setState(() => _data = _data.copyWith(bodyMeasurements: measurements));
  }

  void _selectGoal(Goal goal) {
    setState(() => _data = _data.copyWith(goal: goal));
  }

  void _selectExperience(ExperienceLevel level) {
    setState(() => _data = _data.copyWith(experienceLevel: level));
  }

  void _updateHabits(TrainingHabits habits) {
    setState(() => _data = _data.copyWith(trainingHabits: habits));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: <Widget>[
          // ── Fondo ambiental ──
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.12),
              centerX: 0.5,
              centerY: -0.1,
              radiusX: 0.8,
              radiusY: 0.5,
              fadeStop: 0.6,
            ),
          ),
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.tealA(0.08),
              centerX: 0.8,
              centerY: 0.9,
              radiusX: 0.6,
              radiusY: 0.4,
              fadeStop: 0.6,
            ),
          ),

          // ── Contenido del paso ──
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 70, 24, 112 + bottomInset),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      StepDots(total: _steps.length, current: _step),
                      const SizedBox(height: 32),
                      _buildAnimatedStep(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Barra de progreso (arriba) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OnboardingProgressBar(
              progress: (_step + 1) / _steps.length,
            ),
          ),

          // ── Botón atrás (arriba a la izquierda) y contador de pasos ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 20, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512 + 24),
                    child: Row(
                      children: <Widget>[
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (Widget child, Animation<double> a) =>
                              ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
                          child: _canGoBack
                              ? _BackButton(key: const ValueKey<String>('back'), onTap: _goBack)
                              : const SizedBox(key: ValueKey<String>('none'), width: 42, height: 42),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.whiteA(0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.whiteA(0.10)),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              'Paso ${_step + 1} de ${_steps.length}',
                              key: ValueKey<int>(_step),
                              style: AppText.body(
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.whiteA(0.60),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Navegación (abajo) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OnboardingFooter(
              showBack: false,
              isLast: _isLast,
              nextEnabled: _nextEnabled,
              hint: _missing.isEmpty ? null : 'Para continuar completa: ${_missing.join(', ')}',
              onBack: _goBack,
              onNext: _goNext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStep() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      layoutBuilder: (Widget? current, List<Widget> previous) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previous, if (current != null) current],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool incoming = child.key == ValueKey<OnboardingStep>(_current);
        final double dx = (incoming ? _direction : -_direction) * 32.0;
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
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    final ValueKey<OnboardingStep> key = ValueKey<OnboardingStep>(_current);

    switch (_current) {
      case OnboardingStep.trainer:
        return TrainerStep(
          key: key,
          selected: _data.trainer,
          onSelect: _selectTrainer,
        );
      case OnboardingStep.personalInfo:
        return PersonalInfoStep(
          key: key,
          info: _data.personalInfo,
          onChanged: _updatePersonalInfo,
        );
      case OnboardingStep.measurements:
        return MeasurementsStep(
          key: key,
          measurements: _data.bodyMeasurements,
          onChanged: _updateMeasurements,
        );
      case OnboardingStep.goals:
        return GoalsStep(
          key: key,
          selected: _data.goal,
          onSelect: _selectGoal,
        );
      case OnboardingStep.experience:
        return ExperienceStep(
          key: key,
          selected: _data.experienceLevel,
          onSelect: _selectExperience,
        );
      case OnboardingStep.habits:
        return HabitsStep(
          key: key,
          habits: _data.trainingHabits,
          onChanged: _updateHabits,
        );
    }
  }
}

/// Botón circular de retroceso (arriba a la izquierda).
class _BackButton extends StatelessWidget {
  const _BackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver al paso anterior',
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.whiteA(0.08),
            border: Border.all(color: AppColors.whiteA(0.14)),
          ),
          child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}