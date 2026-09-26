import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback? onNext;

  const OnboardingScreen({
    super.key,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    26,
                    0,
                    26,
                    12,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 5),

                      // ==================================================
                      // PASO
                      // ==================================================

                      Text(
                        'Paso 1 de 7',
                        style: GoogleFonts.exo2(
                          color: AppColors.cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ==================================================
                      // ICONO
                      // ==================================================

                      const _FitnessLogo(),

                      const SizedBox(height: 20),

                      // ==================================================
                      // TITULO
                      // ==================================================

                      Text(
                        '¡Bienvenido a FitZone!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.exo2(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -0.7,
                        ),
                      ),

                      const SizedBox(height: 23),

                      // ==================================================
                      // DESCRIPCION
                      // ==================================================

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                        child: Text(
                          'Vamos a crear tu plan de entrenamiento\n'
                          'personalizado en solo unos pasos',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.exo2(
                            color: Colors.white.withValues(
                              alpha: 0.78,
                            ),
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),

                      const SizedBox(height: 56),

                      // ==================================================
                      // BENEFICIOS
                      // ==================================================

                      const _BenefitCard(
                        icon: Icons.track_changes_rounded,
                        iconColor: AppColors.cyan,
                        title: 'Objetivos Personalizados',
                        subtitle: 'Diseñado para tus metas',
                      ),

                      const SizedBox(height: 16),

                      const _BenefitCard(
                        icon: Icons.monitor_heart_outlined,
                        iconColor: AppColors.cyan,
                        title: 'Seguimiento Completo',
                        subtitle: 'Monitorea tu progreso',
                      ),

                      const SizedBox(height: 16),

                      const _BenefitCard(
                        icon: Icons.workspace_premium_outlined,
                        iconColor: Color(0xFFFFD600),
                        title: 'Entrenadores Profesionales',
                        subtitle: 'Expertos certificados',
                      ),

                      const Spacer(),

                      const SizedBox(height: 44),

                      // ==================================================
                      // PLAN GRATIS
                      // ==================================================

                      Text(
                        '¿Quieres probar primero?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.exo2(
                          color: Colors.white.withValues(
                            alpha: 0.72,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 13),

                      SizedBox(
                        width: double.infinity,
                        height: 49,
                        child: OutlinedButton(
                          onPressed: () {
                            // El flujo del plan gratuito
                            // lo conectaremos con el backend
                            // cuando tengamos el endpoint correspondiente.
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(
                                alpha: 0.13,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Iniciar Plan Gratis 3 Días',
                            style: GoogleFonts.exo2(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==================================================
                      // SIGUIENTE
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton(
                          onPressed: onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Siguiente',
                                style: GoogleFonts.exo2(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 19),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.black,
                                size: 23,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ======================================================================
// LOGO FITNESS
// ======================================================================

class _FitnessLogo extends StatelessWidget {
  const _FitnessLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cyan,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(
              alpha: 0.32,
            ),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: Colors.black,
          size: 47,
        ),
      ),
    );
  }
}

// ======================================================================
// TARJETA DE BENEFICIO
// ======================================================================

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _BenefitCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 79,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.14,
          ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ----------------------------------------------------------
          // ICONO
          // ----------------------------------------------------------

          SizedBox(
            width: 36,
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 18),

          // ----------------------------------------------------------
          // TEXTOS
          // ----------------------------------------------------------

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.exo2(
                    color: Colors.white.withValues(
                      alpha: 0.68,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}