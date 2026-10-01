import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../plan_selection/models/plan.dart';
import 'models/onboarding_data.dart';
import 'models/onboarding_step.dart';
import 'models/personal_info.dart';
import 'models/trainer.dart';
import 'steps/personal_info_step.dart';
import 'steps/placeholder_step.dart';
import 'steps/trainer_step.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/onboarding_progress_bar.dart';
import 'widgets/step_dots.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.planType,
    required this.onComplete,
  });

  final PlanId planType;
  final ValueChanged<OnboardingData> onComplete;

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

  bool get _nextEnabled {
    if (_current == OnboardingStep.trainer) return _data.trainer != null;
    return true;
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
    if (_step == 0) return;
    FocusManager.instance.primaryFocus?.unfocus();
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
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
              padding: EdgeInsets.fromLTRB(24, 32, 24, 112 + bottomInset),
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

          // ── Navegación (abajo) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OnboardingFooter(
              showBack: _step > 0,
              isLast: _isLast,
              nextEnabled: _nextEnabled,
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
      duration: const Duration(milliseconds: 260),
      layoutBuilder: (Widget? current, List<Widget> previous) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previous, if (current != null) current],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool incoming = child.key == ValueKey<OnboardingStep>(_current);
        final double dx = (incoming ? _direction : -_direction) * 28.0;
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
        return PlaceholderStep(
          key: key,
          icon: Icons.straighten_rounded,
          title: 'Mediciones Corporales',
          subtitle: 'Opcionales — te ayudan a ver tu progreso real',
        );
      case OnboardingStep.goals:
        return PlaceholderStep(
          key: key,
          icon: Icons.track_changes_rounded,
          title: '¿Qué quieres lograr?',
          subtitle: 'Selecciona tu objetivo principal',
          teal: true,
        );
      case OnboardingStep.experience:
        return PlaceholderStep(
          key: key,
          icon: Icons.workspace_premium_outlined,
          title: 'Nivel de Experiencia',
          subtitle: '¿Cuánto tiempo llevas entrenando?',
        );
      case OnboardingStep.habits:
        return PlaceholderStep(
          key: key,
          icon: Icons.schedule_rounded,
          title: 'Hábitos de Entrenamiento',
          subtitle: 'Cuéntanos sobre tu rutina diaria',
          teal: true,
        );
    }
  }
}