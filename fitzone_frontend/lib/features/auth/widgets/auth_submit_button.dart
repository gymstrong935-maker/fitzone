import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pulsing_dots.dart';

/// Botón principal con 3 estados: normal, cargando (puntos) y éxito (check verde).
class AuthSubmitButton extends StatefulWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.successLabel,
    required this.loading,
    required this.success,
    required this.onPressed,
  });

  final String label;
  final String successLabel;
  final bool loading;
  final bool success;
  final VoidCallback onPressed;

  @override
  State<AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<AuthSubmitButton> {
  static const Color _ink = Color(0xFF0A0A0A);

  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.loading || widget.success;

    final BoxDecoration decoration;
    if (widget.success) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF34D399), Color(0xFF10B981)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(52, 211, 153, 0.35),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      );
    } else if (widget.loading) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.cyanA(0.45),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: <Color>[AppColors.cyan, AppColors.teal],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.cyanA(0.30),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    final TextStyle textStyle = AppText.body(
      size: 15.2,
      weight: FontWeight.w600,
      color: _ink,
    );

    final Widget content;
    if (widget.loading) {
      content = const PulsingDots(color: _ink, dotSize: 6, gap: 6);
    } else if (widget.success) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _AnimatedCheck(),
          const SizedBox(width: 8),
          Text(widget.successLabel, style: textStyle),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(widget.label, style: textStyle),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: _ink),
        ],
      );
    }

    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _setPressing(true),
      onTapUp: (_) => _setPressing(false),
      onTapCancel: () => _setPressing(false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: (_pressing && !disabled) ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 52,
          alignment: Alignment.center,
          decoration: decoration,
          child: content,
        ),
      ),
    );

    // Al llegar al éxito, el botón "aparece" con escala 0.8 -> 1 y fade.
    if (widget.success) {
      button = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(0.22, 1, 0.36, 1),
        builder: (BuildContext context, double v, Widget? child) {
          return Opacity(
            opacity: v.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
          );
        },
        child: button,
      );
    }

    return button;
  }
}

/// Check que se dibuja trazo a trazo (18x18).
class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (BuildContext context, double t, Widget? _) {
        return CustomPaint(size: const Size(18, 18), painter: _CheckPainter(t));
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(4, 9)
      ..lineTo(7.5, 12.5)
      ..lineTo(14, 6);

    final PathMetric metric = path.computeMetrics().first;
    final double revealed = (50 * progress).clamp(0.0, metric.length).toDouble();

    canvas.drawPath(
      metric.extractPath(0, revealed),
      Paint()
        ..color = const Color(0xFF0A0A0A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}