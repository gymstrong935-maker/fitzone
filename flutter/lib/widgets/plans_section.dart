import 'package:flutter/material.dart';

import 'package:fitzone/models/plan.dart';
import 'package:fitzone/services/plan_service.dart';
import 'package:fitzone/widgets/plan_card.dart';

class PlansSection extends StatelessWidget {
  final Function(Plan) onPlanSelected;

  const PlansSection({
    super.key,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ELIGE TU PLAN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Comienza con el plan que mejor se adapte a ti.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 25),

          FutureBuilder<List<Plan>>(
            future: PlanService.obtenerPlanes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF05C8D8),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'No se pudieron cargar los planes.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                );
              }

              final planes = snapshot.data ?? [];

              if (planes.isEmpty) {
                return const Text(
                  'No hay planes disponibles.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                );
              }

              return Column(
                children: planes.map((plan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PlanCard(
                      plan: plan,
                      onPressed: () {
                        onPlanSelected(plan);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}