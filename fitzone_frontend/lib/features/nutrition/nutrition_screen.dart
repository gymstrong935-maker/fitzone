import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pulsing_dots.dart';
import '../../core/widgets/sub_screen_frame.dart';
import 'models/nutrition_models.dart';
import 'nutrition_controller.dart';
import 'widgets/add_meal_sheet.dart';
import 'widgets/macro_circle.dart';
import 'widgets/meal_card.dart';
import 'widgets/nutrition_card.dart';

/// Pantalla "Nutrición": metas calculadas con tus datos y comidas reales.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({
    super.key,
    required this.controller,
    required this.goals,
    required this.onBack,
  });

  final NutritionController controller;

  /// Metas diarias calculadas con los datos del onboarding.
  final MacroTotals goals;
  final VoidCallback onBack;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  static Color get _green400 => AppColors.green400;
  static Color get _green500 => AppColors.greenStrong;
  static Color get _emerald500 => AppColors.emerald;
  static Color get _yellow500 => AppColors.amberStrong;
  static Color get _orange400 => AppColors.orange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.load();
    });
  }

  Future<void> _confirmDelete(Meal meal) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (BuildContext ctx) => _ConfirmDialog(
        title: '¿Borrar esta comida?',
        message: '${meal.name} de las ${meal.time} (${meal.calories} kcal).',
      ),
    );
    if (confirmed == true) widget.controller.remove(meal);
  }

  @override
  Widget build(BuildContext context) {
    // Esta pantalla tiene fondo negro sólido (no deja ver el degradado global).
    return ColoredBox(
      color: AppColors.bg,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, Widget? _) {
          final NutritionController c = widget.controller;
          final MacroTotals consumed = c.consumed;
          final List<Meal> meals = c.todayMeals;

          return SubScreenFrame(
            title: 'Nutrición',
            subtitle: 'Tu alimentación de hoy',
            large: true,
            onBack: widget.onBack,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (c.error != null) ...<Widget>[
                  ErrorBox(c.error!),
                  const SizedBox(height: 16),
                ],
                FadeSlideIn(
                  duration: const Duration(milliseconds: 400),
                  offsetY: 20,
                  child: _buildCaloriesCard(consumed),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 400),
                  offsetY: 20,
                  child: _buildMacrosCard(consumed),
                ),
                const SizedBox(height: 24),
                _buildMeals(c, meals),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Calorías de hoy ───────────────────────────────────────────────────────
  Widget _buildCaloriesCard(MacroTotals consumed) {
    final int goal = widget.goals.calories;
    final int remaining = goal - consumed.calories;

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
                    '${consumed.calories}',
                    style: AppText.body(
                      size: 30,
                      weight: FontWeight.w700,
                      color: _green400,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'de $goal kcal',
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
                child: Icon(
                  Icons.local_fire_department_outlined,
                  size: 40,
                  color: _green400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          AnimatedProgressBar(
            value: goal <= 0 ? 0 : consumed.calories / goal,
            height: 8,
            animateOnMount: false,
            trackColor: AppColors.cyanA(0.20),
            color: remaining < 0 ? _orange400 : AppColors.cyan,
          ),
          const SizedBox(height: 14),
          Text(
            remaining >= 0
                ? 'Restantes: $remaining kcal'
                : 'Te pasaste por ${-remaining} kcal',
            style: AppText.body(
              size: 14,
              color: remaining >= 0 ? AppColors.whiteA(0.60) : _orange400,
              height: 1.43,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Meta calculada con tu peso, estatura, edad, actividad y objetivo.',
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.35),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Macronutrientes ───────────────────────────────────────────────────────
  Widget _buildMacrosCard(MacroTotals consumed) {
    final MacroTotals goals = widget.goals;

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
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: MacroCircle(
                  label: 'Proteína',
                  current: consumed.protein,
                  goal: goals.protein,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MacroCircle(
                  label: 'Carbos',
                  current: consumed.carbs,
                  goal: goals.carbs,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MacroCircle(
                  label: 'Grasas',
                  current: consumed.fats,
                  goal: goals.fats,
                  color: _yellow500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Comidas del día ───────────────────────────────────────────────────────
  Widget _buildMeals(NutritionController c, List<Meal> meals) {
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
            _AddButton(
              onTap: () => showAddMealSheet(context, onSubmit: c.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!c.loaded && c.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: PulsingDots(dotSize: 6, gap: 6)),
          )
        else if (meals.isEmpty)
          _buildEmpty()
        else
          for (int i = 0; i < meals.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 16),
            FadeSlideIn(
              key: ValueKey<String>(meals[i].id),
              duration: const Duration(milliseconds: 400),
              offsetY: 20,
              child: MealCard(
                meal: meals[i],
                onDelete: () => _confirmDelete(meals[i]),
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildEmpty() {
    return NutritionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const Text('🍽️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'Aún no registraste comidas hoy',
            textAlign: TextAlign.center,
            style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Pulsa "Agregar" para registrar tu primera comida.',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 13,
              color: AppColors.whiteA(0.50),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

/// Botón verde "Agregar".
class _AddButton extends StatefulWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Agregar comida',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _hover ? const Color(0xFF16A34A) : AppColors.greenStrong,
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
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.whiteA(0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.display(size: 20, weight: FontWeight.w700, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 14,
                  color: AppColors.whiteA(0.60),
                  height: 1.43,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DialogButton(
                      label: 'Conservar',
                      background: AppColors.whiteA(0.08),
                      border: AppColors.whiteA(0.12),
                      textColor: AppColors.ink,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: 'Borrar',
                      background: const Color.fromRGBO(239, 68, 68, 0.12),
                      border: const Color.fromRGBO(239, 68, 68, 0.30),
                      textColor: AppColors.red,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.border,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color border;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: textColor,
            height: 1.43,
          ),
        ),
      ),
    );
  }
}