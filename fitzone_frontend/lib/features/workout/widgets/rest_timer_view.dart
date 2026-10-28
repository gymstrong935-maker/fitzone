import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/exercise.dart';

/// Cuando quedan estos segundos (o menos), el descanso se pone en rojo.
const int kRestWarningSeconds = 5;

/// Pantalla de descanso: anillo con cuenta regresiva y el siguiente ejercicio.
/// En los últimos [kRestWarningSeconds] segundos el contador, el anillo y el
/// brillo cambian a rojo y el número "late" en cada segundo.
class RestTimerView extends StatelessWidget {
  const RestTimerView({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.nextExercise,
    required this.onSkip,
    required this.onExtend,
    required this.soundOn,
    required this.onToggleSound,
    required this.onPause,
  });

  final int secondsLeft;
  final int totalSeconds;
  final Exercise nextExercise;
  final VoidCallback onSkip;

  /// Suma unos segundos más al descanso.
  final VoidCallback onExtend;
  final bool soundOn;
  final VoidCallback onToggleSound;

  /// Pausa el entrenamiento.
  final VoidCallback onPause;

  static Color get _cyan400 => AppColors.cyanLightText;

  @override
  Widget build(BuildContext context) {
    final double fraction =
        totalSeconds <= 0 ? 0 : (secondsLeft / totalSeconds).clamp(0.0, 1.0).toDouble();
    final bool urgent = secondsLeft > 0 && secondsLeft <= kRestWarningSeconds;
    final Color numberColor = urgent ? AppColors.redStrong : _cyan400;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (BuildContext context, double v, Widget? child) {
                return Opacity(
                  opacity: v,
                  child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: soundOn ? 'Silenciar sonidos' : 'Activar sonidos',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggleSound,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.whiteA(0.08),
                          ),
                          child: Icon(
                            soundOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 18,
                            color: AppColors.whiteA(soundOn ? 0.70 : 0.40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    urgent ? '¡Casi listo!' : 'Descansa',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 14,
                      weight: urgent ? FontWeight.w700 : FontWeight.w400,
                      color: urgent ? AppColors.red : AppColors.whiteA(0.50),
                      height: 1.43,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prepárate para el siguiente ejercicio',
                    textAlign: TextAlign.center,
                    style: AppText.display(
                      size: 24,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.333,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Anillo ──
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: urgent
                            ? const <BoxShadow>[
                                BoxShadow(
                                  color: Color.fromRGBO(239, 68, 68, 0.38),
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                ),
                              ]
                            : const <BoxShadow>[],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: fraction),
                            duration: const Duration(milliseconds: 500),
                            builder: (
                              BuildContext context,
                              double value,
                              Widget? _,
                            ) {
                              return CustomPaint(
                                size: const Size(176, 176),
                                painter: _RestRingPainter(value, urgent),
                              );
                            },
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _RestNumber(
                                seconds: secondsLeft,
                                color: numberColor,
                                urgent: urgent,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'segundos',
                                style: AppText.body(
                                  size: 12,
                                  weight:
                                      urgent ? FontWeight.w700 : FontWeight.w400,
                                  color: urgent
                                      ? AppColors.red
                                      : AppColors.whiteA(0.45),
                                  height: 1.333,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── +15 s / Saltar descanso ──
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _RestButton(
                          label: '+15 s',
                          onTap: onExtend,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RestButton(
                          label: 'Pausa',
                          onTap: onPause,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _RestButton(
                          label: 'Saltar Descanso',
                          onTap: onSkip,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Siguiente ejercicio ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cyanA(0.07),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cyanA(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Siguiente ejercicio',
                          style: AppText.body(
                            size: 12,
                            color: AppColors.whiteA(0.45),
                            height: 1.333,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextExercise.name,
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                            height: 1.43,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nextExercise.muscleGroup} · ${nextExercise.sets} series × ${nextExercise.reps} reps',
                          style: AppText.body(
                            size: 12,
                            color: _cyan400,
                            height: 1.333,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El número grande. En rojo "late": nace más grande y se encoge cada segundo.
class _RestNumber extends StatelessWidget {
  const _RestNumber({
    required this.seconds,
    required this.color,
    required this.urgent,
  });

  final int seconds;
  final Color color;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final Text text = Text(
      '$seconds',
      style: AppText.display(
        size: 48,
        weight: FontWeight.w700,
        color: color,
        height: 1,
      ),
    );

    if (!urgent) return text;

    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(seconds),
      tween: Tween<double>(begin: 1.35, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: text,
    );
  }
}

class _RestButton extends StatelessWidget {
  const _RestButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.whiteA(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.whiteA(0.15)),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.ink,
            height: 1.43,
          ),
        ),
      ),
    );
  }
}

class _RestRingPainter extends CustomPainter {
  const _RestRingPainter(this.fraction, this.urgent);

  final double fraction;

  /// `true` en los últimos segundos: el anillo se dibuja en rojo.
  final bool urgent;

  // El diseño usa un lienzo de 192 con radio 80 y trazo 8; aquí el anillo
  // mide 176, así que todo se escala por 176 / 192.
  static const double _scale = 176 / 192;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = 80 * _scale;
    final double stroke = 8 * _scale;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.whiteA(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    final double sweep = 2 * math.pi * fraction.clamp(0.0, 1.0).toDouble();
    if (sweep <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = LinearGradient(
          colors: urgent
              ? const <Color>[Color(0xFFEF4444), Color(0xFFF97316)]
              : const <Color>[AppColors.cyan, AppColors.teal],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RestRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.urgent != urgent;
  }
}