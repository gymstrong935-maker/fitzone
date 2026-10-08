import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra de progreso redondeada que se llena con animación.
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.animateOnMount = true,
    this.trackColor = const Color.fromRGBO(255, 255, 255, 0.08),
    this.color,
    this.gradient,
  });

  /// Avance de 0.0 a 1.0.
  final double value;
  final double height;

  /// Espera antes de empezar a llenarse (solo con [animateOnMount]).
  final Duration delay;
  final Duration duration;

  /// `true`: parte de vacío y se llena al aparecer; `false`: aparece ya llena.
  final bool animateOnMount;
  final Color trackColor;

  /// Color sólido del relleno. Si no se da color ni degradado, usa el degradado
  /// cian-turquesa.
  final Color? color;
  final Gradient? gradient;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  Timer? _timer;
  late bool _started;

  @override
  void initState() {
    super.initState();
    _started = !widget.animateOnMount;
    if (widget.animateOnMount) {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _started = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(999);
    final double factor =
        _started ? widget.value.clamp(0.0, 1.0).toDouble() : 0.0;

    final Gradient? gradient = widget.gradient ??
        (widget.color == null
            ? const LinearGradient(
                colors: <Color>[AppColors.cyan, AppColors.teal],
              )
            : null);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: ColoredBox(color: widget.trackColor)),
            Positioned.fill(
              child: AnimatedFractionallySizedBox(
                duration: widget.duration,
                curve: Curves.easeInOut,
                alignment: Alignment.centerLeft,
                widthFactor: factor,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: gradient == null ? widget.color : null,
                    gradient: gradient,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}