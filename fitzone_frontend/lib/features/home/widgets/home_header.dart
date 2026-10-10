import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ellipse_glow.dart';
import '../../../core/widgets/fade_slide_in.dart';

/// Cabecera de Inicio: fondo con degradado, anillos decorativos, saludo,
/// nombre, frase del día y pastillas de estadísticas.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.quote,
    required this.pills,
    this.trailing,
  });

  final String greeting;
  final String name;
  final String quote;
  final List<Widget> pills;

  /// Widget de la esquina superior derecha (la campana de notificaciones).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final double paddingTop = math.max(48.0, topInset + 16);

    final ScrollBehavior pillsBehavior =
        ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
      dragDevices: <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      },
    );

    return ClipRect(
      child: Stack(
        children: <Widget>[
          // ── Fondo ──
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0A1628),
                    Color(0xFF071E20),
                    Color(0xFF0A0F1E),
                  ],
                  stops: <double>[0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.18),
              centerX: 0.3,
              centerY: 0.4,
              radiusX: 0.7,
              radiusY: 0.6,
              fadeStop: 0.65,
            ),
          ),
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.tealA(0.12),
              centerX: 0.8,
              centerY: 0.7,
              radiusX: 0.5,
              radiusY: 0.5,
              fadeStop: 0.6,
            ),
          ),

          // ── Anillos decorativos (arriba a la derecha) ──
          Positioned(
            top: -40,
            right: -40,
            width: 208,
            height: 208,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cyanA(0.12)),
                ),
              ),
            ),
          ),
          Positioned(
            top: -16,
            right: -16,
            width: 144,
            height: 144,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cyanA(0.07)),
                ),
              ),
            ),
          ),

          // ── Desvanecido hacia negro (abajo) ──
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x00000000), Color(0xFF000000)],
                  ),
                ),
              ),
            ),
          ),

          // ── Contenido ──
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 210),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, paddingTop, 20, 24),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      FadeSlideIn(
                        duration: const Duration(milliseconds: 450),
                        offsetY: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '$greeting 👋',
                              style: AppText.body(
                                size: 14,
                                color: AppColors.whiteA(0.45),
                                height: 1.43,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(right: 52),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.display(
                                  size: 24,
                                  letterSpacing: -0.48,
                                  height: 1.333,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                quote,
                                style: AppText.body(
                                  size: 12,
                                  color: AppColors.whiteA(0.38),
                                  height: 1.625,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ScrollConfiguration(
                              behavior: pillsBehavior,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: <Widget>[
                                    for (int i = 0; i < pills.length; i++) ...<Widget>[
                                      if (i > 0) const SizedBox(width: 8),
                                      pills[i],
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null)
                        Positioned(top: 0, right: 0, child: trailing!),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}