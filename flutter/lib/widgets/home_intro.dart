import 'package:flutter/material.dart';

import 'package:fitzone/widgets/fitzone_button.dart';

class HomeIntro extends StatelessWidget {
  final VoidCallback onStartPressed;

  const HomeIntro({
    super.key,
    required this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),

          const Text(
            'ENTRENA.\nMEJORA.\nTRANSFORMA.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'FITZONE te ayuda a mejorar tu entrenamiento '
            'con planes personalizados y seguimiento de tu progreso.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          FitZoneButton(
            text: 'COMENZAR AHORA',
            onPressed: onStartPressed,
          ),
        ],
      ),
    );
  }
}