import 'package:flutter/material.dart';

class AdvantagesSection extends StatelessWidget {
  const AdvantagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VENTAJAS DE FITZONE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _crearVentaja(
            icono: Icons.fitness_center,
            titulo: 'Entrenamiento personalizado',
            descripcion:
                'Obtén una experiencia adaptada a tus objetivos.',
          ),

          _crearVentaja(
            icono: Icons.monitor_heart,
            titulo: 'Seguimiento',
            descripcion:
                'Lleva un mejor control de tu progreso.',
          ),

          _crearVentaja(
            icono: Icons.restaurant,
            titulo: 'Control nutricional',
            descripcion:
                'Consulta información relacionada con tu alimentación.',
          ),

          _crearVentaja(
            icono: Icons.calendar_month,
            titulo: 'Organización',
            descripcion:
                'Administra tus entrenamientos y actividades.',
          ),
        ],
      ),
    );
  }

  Widget _crearVentaja({
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: const Color(0xFF05C8D8),
            size: 30,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  descripcion,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
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