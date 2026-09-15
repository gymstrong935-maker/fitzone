import 'package:flutter/material.dart';

import 'package:fitzone/widgets/fitzone_button.dart';
import 'package:fitzone/widgets/plan_step_header.dart';
import 'package:fitzone/pages/plans/trainer_selection_page.dart';

class PlanWelcomePage extends StatelessWidget {
  const PlanWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const PlanStepHeader(
                paso: 'Paso 1 de 7',
                titulo: '¡Bienvenido a FitZone!',
                subtitulo:
                    'Vamos a crear tu plan de entrenamiento '
                    'personalizado en solo unos pasos',
              ),

              const SizedBox(height: 30),

              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF05C8D8),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6605C8D8),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.black,
                  size: 48,
                ),
              ),

              const SizedBox(height: 35),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _crearBeneficio(
                        Icons.track_changes,
                        'Objetivos Personalizados',
                        'Diseñado para tus metas',
                      ),

                      _crearBeneficio(
                        Icons.monitor_heart,
                        'Seguimiento Completo',
                        'Monitorea tu progreso',
                      ),

                      _crearBeneficio(
                        Icons.workspace_premium,
                        'Entrenadores Profesionales',
                        'Expertos certificados',
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        '¿Quieres probar primero?',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Plan Gratis de 3 días seleccionado',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Iniciar Plan Gratis 3 Días',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              FitZoneButton(
                text: 'Siguiente  ›',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const TrainerSelectionPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearBeneficio(
    IconData icono,
    String titulo,
    String descripcion,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: const Color(0xFF05C8D8),
            size: 27,
          ),

          const SizedBox(width: 15),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                descripcion,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}