import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra superior de 3 px con degradado cian/turquesa en movimiento continuo.
class ShimmerTopBar extends StatefulWidget {
  const ShimmerTopBar({super.key, this.height = 3});

  final double height;

  @override
  State<ShimmerTopBar> createState() => _ShimmerTopBarState();
}

class _ShimmerTopBarState extends State<ShimmerTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(painter: _ShimmerPainter(_controller)),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  static const List<Color> _colors = <Color>[
    AppColors.cyan,
    AppColors.teal,
    AppColors.cyanLight,
    AppColors.teal,
    AppColors.cyan,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // El degradado mide 2.5x el ancho y se repite; se desplaza a la izquierda
    // un "tile" completo por ciclo, así el bucle no tiene saltos.
    final double tileWidth = size.width * 2.5;
    final Rect gradientRect = Rect.fromLTWH(
      -progress.value * tileWidth,
      0,
      tileWidth,
      size.height,
    );

    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: _colors,
        tileMode: TileMode.repeated,
      ).createShader(gradientRect);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}