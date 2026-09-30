import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ellipse_glow.dart';

/// Marco compartido de los pasos del onboarding.
/// [step] empieza en 0. El último paso muestra "Finalizar configuración".
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.onNext,
    required this.child,
    this.onBack,
    this.nextEnabled = true,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onNext;

  /// Si es null, no se muestra el botón de volver (como en el primer paso).
  final VoidCallback? onBack;
  final bool nextEnabled;
  final Widget child;

  static const double _maxWidth = 512;

  @override
  Widget build(BuildContext context) {
    final double progress = (step + 1) / totalSteps;

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

          // ── Contenido con scroll ──
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 136),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _StepDots(step: step, total: totalSteps),
                        const SizedBox(height: 32),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Barra inferior fija ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _NavFooter(
              isLast: step == totalSteps - 1,
              nextEnabled: nextEnabled,
              onNext: onNext,
              onBack: onBack,
            ),
          ),

          // ── Barra de progreso superior ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ProgressBar(progress: progress),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Barra de progreso
// ═══════════════════════════════════════════════════════════════════════════

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: ColoredBox(color: AppColors.whiteA(0.10))),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (BuildContext context, double value, Widget? _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                heightFactor: 1.0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[AppColors.cyan, AppColors.teal],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Puntos de pasos
// ═══════════════════════════════════════════════════════════════════════════

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == step ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: i == step
                  ? const LinearGradient(
                      colors: <Color>[AppColors.cyan, AppColors.teal],
                    )
                  : null,
              color: i == step
                  ? null
                  : (i < step ? AppColors.cyanA(0.5) : AppColors.whiteA(0.15)),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Barra inferior (Volver / Siguiente)
// ═══════════════════════════════════════════════════════════════════════════

class _NavFooter extends StatelessWidget {
  const _NavFooter({
    required this.isLast,
    required this.nextEnabled,
    required this.onNext,
    this.onBack,
  });

  final bool isLast;
  final bool nextEnabled;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            Colors.black,
            Color.fromRGBO(0, 0, 0, 0.95),
            Color.fromRGBO(0, 0, 0, 0),
          ],
          stops: <double>[0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, math.max(32.0, bottomInset)),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 512),
            child: Row(
              children: <Widget>[
                if (onBack != null) ...<Widget>[
                  _BackButton(onTap: onBack!),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _NextButton(
                    isLast: isLast,
                    enabled: nextEnabled,
                    onTap: onNext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 60,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.whiteA(0.15)),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  const _NextButton({
    required this.isLast,
    required this.enabled,
    required this.onTap,
  });

  final bool isLast;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppText.body(
      size: 16,
      weight: FontWeight.w600,
      color: Colors.black,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _setPressing(true) : null,
      onTapUp: (_) => _setPressing(false),
      onTapCancel: () => _setPressing(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: (_pressing && widget.enabled) ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: <Color>[AppColors.cyan, AppColors.teal],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.isLast ? 'Finalizar configuración' : 'Siguiente',
                  style: style,
                ),
                if (!widget.isLast) ...<Widget>[
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Colors.black,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}