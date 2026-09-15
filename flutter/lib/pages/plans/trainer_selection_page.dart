import 'package:flutter/material.dart';

import 'package:fitzone/models/trainer.dart';
import 'package:fitzone/widgets/fitzone_button.dart';
import 'package:fitzone/widgets/plan_step_header.dart';
import 'package:fitzone/widgets/trainer_card.dart';
import 'package:fitzone/pages/plans/payment_page.dart';

class TrainerSelectionPage extends StatefulWidget {
  const TrainerSelectionPage({super.key});

  @override
  State<TrainerSelectionPage> createState() =>
      _TrainerSelectionPageState();
}

class _TrainerSelectionPageState
    extends State<TrainerSelectionPage> {
  Trainer? entrenadorSeleccionado;

  final List<Trainer> entrenadores = [
    Trainer(
      id: '1',
      nombre: 'Ana Martínez',
      especialidad: 'Hipertrofia y Fuerza',
      calificacion: 4.9,
      experiencia: 8,
      descripcion:
          'Especialista en desarrollo muscular y programas de fuerza adaptados a cada nivel.',
      precio: '\$89',
      imagen: '',
      certificaciones: [
        'NSCA-CPT',
        'ISSA Bodybuilding',
        'Nutrición Deportiva',
      ],
    ),

    Trainer(
      id: '2',
      nombre: 'Carlos Rodríguez',
      especialidad: 'Recomposición Corporal',
      calificacion: 4.8,
      experiencia: 10,
      descripcion:
          'Experto en transformación física combinando entrenamiento y nutrición estratégica.',
      precio: '\$129',
      imagen: '',
      certificaciones: [
        'ACE',
        'Precision Nutrition Level 2',
        'NASM-PES',
      ],
    ),
  ];

  void seleccionarEntrenador(Trainer entrenador) {
    setState(() {
      entrenadorSeleccionado = entrenador;
    });
  }

  void siguiente() {
    if (entrenadorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un entrenador para continuar',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          entrenador: entrenadorSeleccionado!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            const PlanStepHeader(
              paso: 'Paso 2 de 7',
              titulo: 'Selecciona tu Entrenador',
              subtitulo:
                  'Elige al profesional que mejor se adapte a ti',
            ),

            const SizedBox(height: 25),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00191C),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF05C8D8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Por qué necesitas un entrenador?',
                            style: TextStyle(
                              color: Color(0xFF05C8D8),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          _crearBeneficio(
                            '🎯',
                            'Mayor Personalización',
                            'Plan 100% adaptado a tus necesidades, objetivos y condiciones específicas',
                          ),

                          _crearBeneficio(
                            '🛡️',
                            'Reducción de Lesiones',
                            'Supervisión profesional que minimiza riesgos y corrige tu técnica',
                          ),

                          _crearBeneficio(
                            '📈',
                            'Mejor Progreso',
                            'Resultados más rápidos y efectivos con seguimiento constante',
                          ),

                          _crearBeneficio(
                            '💼',
                            'Plan Profesional',
                            'Programación científica basada en evidencia y experiencia certificada',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    ...entrenadores.map(
                      (entrenador) {
                        return TrainerCard(
                          trainer: entrenador,
                          seleccionado:
                              entrenadorSeleccionado?.id ==
                                  entrenador.id,
                          onPressed: () {
                            seleccionarEntrenador(
                              entrenador,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: FitZoneButton(
                      text: '‹  Anterior',
                      outlined: true,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FitZoneButton(
                      text: 'Siguiente  ›',
                      onPressed: siguiente,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crearBeneficio(
    String emoji,
    String titulo,
    String descripcion,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF001214),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  descripcion,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
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