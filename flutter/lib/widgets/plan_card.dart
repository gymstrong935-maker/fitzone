import 'package:flutter/material.dart';
import '../models/plan.dart';
import 'fitzone_button.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onPressed;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool gratuito = plan.esGratuito;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gratuito
              ? Colors.white24
              : const Color(0xFF05C8D8),
          width: gratuito ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!gratuito)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF05C8D8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'RECOMENDADO',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (!gratuito)
            const SizedBox(height: 15),

          Text(
            plan.nombre.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            gratuito
                ? '${plan.duracionDias} días gratis'
                : '\$${plan.precio.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF05C8D8),
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (!gratuito)
            Text(
              plan.duracionDias >= 365
                  ? 'por año'
                  : 'por mes',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),

          const SizedBox(height: 18),

          const Divider(
            color: Colors.white12,
          ),

          const SizedBox(height: 12),

          ...plan.beneficios.map(
            (beneficio) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 9,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check,
                      color: Color(0xFF05C8D8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        beneficio,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          FitZoneButton(
            text: gratuito
                ? 'COMENZAR GRATIS'
                : 'ELEGIR PLAN',
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}