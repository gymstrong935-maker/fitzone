import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ellipse_glow.dart';

/// Gradiente ambiental global de la app principal:
/// círculo cian al 15 %/25 % y círculo turquesa al 85 %/75 %.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }

        // En CSS el círculo llega a la esquina más lejana; el color se
        // desvanece al 45 % de ese radio.
        double radiusFor(double cx, double cy) {
          final double dx = math.max(cx * w, (1 - cx) * w);
          final double dy = math.max(cy * h, (1 - cy) * h);
          return math.sqrt(dx * dx + dy * dy) * 0.45;
        }

        final double r1 = radiusFor(0.15, 0.25);
        final double r2 = radiusFor(0.85, 0.75);

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: EllipseGlow(
                color: AppColors.cyanA(0.07),
                centerX: 0.15,
                centerY: 0.25,
                radiusX: r1 / w,
                radiusY: r1 / h,
                fadeStop: 1.0,
              ),
            ),
            Positioned.fill(
              child: EllipseGlow(
                color: AppColors.tealA(0.07),
                centerX: 0.85,
                centerY: 0.75,
                radiusX: r2 / w,
                radiusY: r2 / h,
                fadeStop: 1.0,
              ),
            ),
          ],
        );
      },
    );
  }
}