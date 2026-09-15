import 'package:flutter/material.dart';

class PlanStepHeader extends StatelessWidget {
  final String paso;
  final String titulo;
  final String subtitulo;

  const PlanStepHeader({
    super.key,
    required this.paso,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          paso,
          style: const TextStyle(
            color: Color(0xFF05C8D8),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 25),

        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}