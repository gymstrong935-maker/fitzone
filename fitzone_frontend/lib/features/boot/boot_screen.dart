import 'package:flutter/material.dart';

import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import '../auth/widgets/auth_background.dart';
import '../auth/widgets/auth_logo.dart';

/// Pantalla de arranque: se muestra mientras se recupera la sesión guardada.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: AuthBackground()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AuthLogo(),
                SizedBox(height: 32),
                PulsingDots(dotSize: 6, gap: 6),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ShimmerTopBar(),
          ),
        ],
      ),
    );
  }
}