import 'package:flutter/material.dart';

/// Animación de entrada: aparece con fade y se desliza hasta su posición.
/// `offsetY` > 0 entra desde abajo, < 0 entra desde arriba.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
    this.offsetY = 28,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final Duration total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);

    final double begin = widget.delay.inMilliseconds / total.inMilliseconds;
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, 1.0, curve: const Cubic(0.22, 1, 0.36, 1)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double v = _animation.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offsetY),
            child: child,
          ),
        );
      },
    );
  }
}