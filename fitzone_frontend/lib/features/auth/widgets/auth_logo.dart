import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Logo "FZ" de 72 px que flota y emite un anillo pulsante.
class AuthLogo extends StatefulWidget {
  const AuthLogo({super.key});

  @override
  State<AuthLogo> createState() => _AuthLogoState();
}

class _AuthLogoState extends State<AuthLogo> with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _ring;
  Timer? _floatTimer;
  Timer? _ringTimer;
  bool _ringStarted = false;

  @override
  void initState() {
    super.initState();
    // Ciclo completo de flote = 4.5 s (2.25 s subiendo + 2.25 s bajando).
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2250),
    );
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _floatTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) _float.repeat(reverse: true);
    });
    _ringTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _ringStarted = true);
      _ring.repeat();
    });
  }

  @override
  void dispose() {
    _floatTimer?.cancel();
    _ringTimer?.cancel();
    _float.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_float, _ring]),
      builder: (BuildContext context, Widget? _) {
        final double dy = -7 * Curves.easeInOut.transform(_float.value);
        final double e = Curves.easeOut.transform(_ring.value);

        return Transform.translate(
          offset: Offset(0, dy),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                if (_ringStarted)
                  Opacity(
                    opacity: 0.7 * (1 - e),
                    child: Transform.scale(
                      scale: 0.85 + 1.35 * e,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.cyanA(0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                _buildCircle(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircle() {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.cyanA(0.24), AppColors.tealA(0.14)],
        ),
        border: Border.all(color: AppColors.cyanA(0.5), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(color: AppColors.cyanA(0.22), blurRadius: 36),
          BoxShadow(color: AppColors.cyanA(0.08), blurRadius: 72),
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
          style: AppText.display(size: 24, color: Colors.white),
        ),
      ),
    );
  }
}