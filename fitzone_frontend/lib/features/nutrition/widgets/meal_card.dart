import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/nutrition_models.dart';
import 'nutrition_card.dart';

/// Tarjeta de una comida: nombre, hora, calorías, macros y alimentos.
class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.meal});

  final Meal meal;

  static const Color _green400 = Color(0xFF4ADE80);
  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _teal400 = Color(0xFF2DD4BF);
  static const Color _yellow400 = Color(0xFFFACC15);

  @override
  Widget build(BuildContext context) {
    return NutritionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Nombre + hora | calorías ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    meal.name,
                    style: AppText.display(
                      size: 18,
                      weight: FontWeight.w600,
                      height: 1.556,
                    ),
                  ),
                  Text(
                    meal.time,
                    style: AppText.body(
                      size: 14,
                      color: AppColors.whiteA(0.60),
                      height: 1.43,
                    ),
                  ),
                ],
              ),
              Text(
                '${meal.calories} kcal',
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w700,
                  color: _green400,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // ── Macros ──
          Row(
            children: <Widget>[
              Expanded(
                child: _MacroCell(
                  label: 'Proteína',
                  value: meal.protein,
                  color: _cyan400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroCell(
                  label: 'Carbos',
                  value: meal.carbs,
                  color: _teal400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroCell(
                  label: 'Grasas',
                  value: meal.fats,
                  color: _yellow400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // ── Alimentos ──
          for (int i = 0; i < meal.foods.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    meal.foods[i].name,
                    style: AppText.body(
                      size: 14,
                      color: AppColors.whiteA(0.80),
                      height: 1.43,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${meal.foods[i].quantity} ${meal.foods[i].unit}',
                  style: AppText.body(
                    size: 14,
                    color: AppColors.whiteA(0.60),
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.60),
              height: 1.333,
            ),
          ),
          Text(
            '${value}g',
            style: AppText.body(
              size: 16,
              weight: FontWeight.w600,
              color: color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}