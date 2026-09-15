import 'package:flutter/material.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿CÓMO FUNCIONA?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _crearPaso(
            numero: '01',
            titulo: 'ELIGE TU PLAN',
            descripcion:
                'Selecciona el plan que mejor se adapte a tus necesidades.',
          ),

          _crearPaso(
            numero: '02',
            titulo: 'COMPLETA TU INFORMACIÓN',
            descripcion:
                'Registra tus datos y la información necesaria para tu entrenamiento.',
          ),

          _crearPaso(
            numero: '03',
            titulo: 'COMIENZA A ENTRENAR',
            descripcion:
                'Recibe herramientas para llevar un mejor control de tu entrenamiento.',
          ),
        ],
      ),
    );
  }

  Widget _crearPaso({
    required String numero,
    required String titulo,
    required String descripcion,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            numero,
            style: const TextStyle(
              color: Color(0xFF05C8D8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  descripcion,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.4,
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