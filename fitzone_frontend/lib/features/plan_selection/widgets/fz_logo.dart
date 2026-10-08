import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Logo circular "FZ" que flota suavemente (empieza a flotar 1 s después).
class FzLogo extends StatefulWidget {
  const FzLogo({super.key});

  @override
  State<FzLogo> createState() => _FzLogoState();
}

class _FzLogoState extends State<FzLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dy;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _dy = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _startTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dy,
      child: _buildCircle(),
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(offset: Offset(0, _dy.value), child: child);
      },
    );
  }

  Widget _buildCircle() {
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.cyanA(0.22), AppColors.tealA(0.12)],
        ),
        border: Border.all(color: AppColors.cyanA(0.45), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(color: AppColors.cyanA(0.22), blurRadius: 28),
        ],
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.cyan, AppColors.teal],
          ).createShader(bounds);
        },
        child: Text(
          'FZ',
          style: AppText.display(size: 22.4, color: Colors.white),
        ),
      ),
    );
  }
}