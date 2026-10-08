import 'package:flutter/material.dart';

/// Envuelve un widget con escala al presionar y, opcionalmente, al pasar el
/// cursor (equivale a whileTap / whileHover de la versión web).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.onTap,
    required this.child,
    this.pressedScale = 0.96,
    this.hoverScale = 1.0,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double pressedScale;
  final double hoverScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressing = false;
  bool _hover = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  void _setHover(bool value) {
    if (_hover != value) setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    final double scale =
        _pressing ? widget.pressedScale : (_hover ? widget.hoverScale : 1.0);

    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressing(true),
        onTapUp: (_) => _setPressing(false),
        onTapCancel: () => _setPressing(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}