import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/sub_screen_frame.dart';
import 'data/nutrition_data.dart';
import 'models/nutrition_models.dart';
import 'widgets/macro_circle.dart';
import 'widgets/meal_card.dart';
import 'widgets/nutrition_card.dart';

/// Pantalla "Nutrición".
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  static const Color _green400 = Color(0xFF4ADE80);
  static const Color _green500 = Color(0xFF22C55E);
  static const Color _emerald500 = Color(0xFF10B981);
  static const Color _yellow500 = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    // Esta pantalla tiene fondo negro sólido (no deja ver el degradado global).
    return ColoredBox(
      color: Colors.black,
      child: SubScreenFrame(
        title: 'Nutrición',
        subtitle: 'Plan alimenticio personalizado',
        large: true,
        onBack: onBack,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FadeSlideIn(
              duration: const Duration(milliseconds: 400),
              offsetY: 20,
              child: _buildCaloriesCard(),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              offsetY: 20,
              child: _buildMacrosCard(),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 400),
              offsetY: 20,
              child: _buildOtherNutrientsCard(),
            ),
            const SizedBox(height: 24),
            _buildMeals(),
          ],
        ),
      ),
    );
  }

  // ── Calorías de hoy ───────────────────────────────────────────────────────
  Widget _buildCaloriesCard() {
    final int remaining = kDailyGoals.calories - kConsumed.calories;

    return NutritionCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          _green500.withAlpha(51), // 20 %
          _emerald500.withAlpha(51),
        ],
      ),
      borderColor: _green500.withAlpha(77), // 30 %
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Calorías Hoy',
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${kConsumed.calories}',
                    style: AppText.body(
                      size: 30,
                      weight: FontWeight.w700,
                      color: _green400,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'de ${kDailyGoals.calories} kcal',
                    style: AppText.body(
                      size: 14,
                      color: AppColors.whiteA(0.60),
                      height: 1.43,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green500.withAlpha(51),
                ),
                child: const Icon(
                  Icons.local_fire_department_outlined,
                  size: 40,
                  color: _green400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          AnimatedProgressBar(
            value: kConsumed.calories / kDailyGoals.calories,
            height: 8,
            animateOnMount: false,
            trackColor: AppColors.cyanA(0.20),
            color: AppColors.cyan,
          ),
          const SizedBox(height: 32),
          Text(
            'Restantes: $remaining kcal',
            style: AppText.body(
              size: 14,
              color: AppColors.whiteA(0.60),
              height: 1.43,
            ),
          ),
        ],
      ),
    );
  }

  // ── Macronutrientes ───────────────────────────────────────────────────────
  Widget _buildMacrosCard() {
    return NutritionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Macronutrientes',
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: MacroCircle(
                  label: 'Proteína',
                  current: kConsumed.protein,
                  goal: kDailyGoals.protein,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MacroCircle(
                  label: 'Carbos',
                  current: kConsumed.carbs,
                  goal: kDailyGoals.carbs,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MacroCircle(
                  label: 'Grasas',
                  current: kConsumed.fats,
                  goal: kDailyGoals.fats,
                  color: _yellow500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Otros nutrientes ──────────────────────────────────────────────────────
  Widget _buildOtherNutrientsCard() {
    return NutritionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Otros Nutrientes',
            style: AppText.display(
              size: 18,
              weight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          for (int i = 0; i < kExtraNutrients.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            _NutrientRow(nutrient: kExtraNutrients[i]),
          ],
        ],
      ),
    );
  }

  // ── Comidas del día ───────────────────────────────────────────────────────
  Widget _buildMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Comidas del Día',
              style: AppText.display(
                size: 18,
                weight: FontWeight.w700,
                height: 1.556,
              ),
            ),
            const _AddButton(),
          ],
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < kMeals.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 16),
          FadeSlideIn(
            delay: Duration(milliseconds: 300 + i * 100),
            duration: const Duration(milliseconds: 400),
            offsetY: 20,
            child: MealCard(meal: kMeals[i]),
          ),
        ],
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.nutrient});

  final ExtraNutrient nutrient;

  @override
  Widget build(BuildContext context) {
    final int? max = nutrient.max;
    final String valueText = max == null
        ? '${nutrient.value}${nutrient.unit}'
        : '${nutrient.value}${nutrient.unit} / $max${nutrient.unit}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              nutrient.name,
              style: AppText.body(
                size: 14,
                color: AppColors.whiteA(0.80),
                height: 1.43,
              ),
            ),
            Text(
              valueText,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: Colors.white,
                height: 1.43,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (max != null)
          AnimatedProgressBar(
            value: nutrient.value / max,
            height: 6,
            animateOnMount: false,
            trackColor: AppColors.cyanA(0.20),
            color: AppColors.cyan,
          ),
      ],
    );
  }
}

/// Botón verde "Agregar" (el diseño aún no define ninguna acción).
class _AddButton extends StatefulWidget {
  const _AddButton();

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFF16A34A) : const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.add_rounded, size: 16, color: Colors.black),
            const SizedBox(width: 14),
            Text(
              'Agregar',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                color: Colors.black,
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }
}