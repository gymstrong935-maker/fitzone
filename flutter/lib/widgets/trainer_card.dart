import 'package:flutter/material.dart';

import 'package:fitzone/models/trainer.dart';

class TrainerCard extends StatelessWidget {
  final Trainer trainer;
  final bool seleccionado;
  final VoidCallback onPressed;

  const TrainerCard({
    super.key,
    required this.trainer,
    required this.seleccionado,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF080808),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF05C8D8)
                : Colors.white12,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        trainer.especialidad,
                        style: const TextStyle(
                          color: Color(0xFF05C8D8),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 18,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            trainer.calificacion.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Text(
                            '${trainer.experiencia} años',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trainer.precio,
                      style: const TextStyle(
                        color: Color(0xFF05C8D8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Text(
                      '/mes',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              trainer.descripcion,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trainer.certificaciones.map((certificacion) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    certificacion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),

            if (seleccionado) ...[
              const SizedBox(height: 12),

              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF05C8D8),
                    size: 20,
                  ),

                  SizedBox(width: 8),

                  Text(
                    'Entrenador seleccionado',
                    style: TextStyle(
                      color: Color(0xFF05C8D8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}