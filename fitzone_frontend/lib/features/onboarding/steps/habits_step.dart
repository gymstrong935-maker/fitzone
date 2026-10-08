import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/training_habits.dart';
import '../widgets/fz_label.dart';
import '../widgets/fz_number_field.dart' show formatNumber;
import '../widgets/fz_select.dart';
import '../widgets/fz_slider.dart';
import '../widgets/step_header.dart';

/// Paso "Hábitos de Entrenamiento" (último del onboarding).
class HabitsStep extends StatelessWidget {
  const HabitsStep({super.key, required this.habits, required this.onChanged});

  final TrainingHabits habits;
  final ValueChanged<TrainingHabits> onChanged;

  @override
  Widget build(BuildContext context) {
    final String frequencyText =
        habits.frequency == 1 ? '1 día' : '${habits.frequency} días';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const StepHeader(
          icon: Icons.schedule_rounded,
          title: 'Hábitos de Entrenamiento',
          subtitle: 'Cuéntanos sobre tu rutina diaria',
          teal: true,
        ),
        const SizedBox(height: 24),

        // Frecuencia semanal (1 a 7 días).
        FzStepSliderField(
          label: 'Frecuencia semanal',
          valueText: frequencyText,
          value: habits.frequency.toDouble(),
          min: 1,
          max: 7,
          step: 1,
          minLabel: '1 día',
          maxLabel: '7 días',
          onChanged: (double v) =>
              onChanged(habits.copyWith(frequency: v.round())),
        ),
        const SizedBox(height: 20),

        // Duración por sesión (30 a 120 min, de 15 en 15).
        FzStepSliderField(
          label: 'Duración por sesión',
          valueText: '${habits.duration} min',
          value: habits.duration.toDouble(),
          min: 30,
          max: 120,
          step: 15,
          minLabel: '30 min',
          maxLabel: '2 horas',
          onChanged: (double v) =>
              onChanged(habits.copyWith(duration: v.round())),
        ),
        const SizedBox(height: 20),

        // Calidad del sueño.
        const FzLabel('Calidad del Sueño'),
        const SizedBox(height: 6),
        FzSelect<SleepQuality>(
          value: habits.sleepQuality,
          options: const <FzSelectOption<SleepQuality>>[
            FzSelectOption<SleepQuality>(
              value: SleepQuality.poor,
              label: 'Mala',
            ),
            FzSelectOption<SleepQuality>(
              value: SleepQuality.fair,
              label: 'Regular',
            ),
            FzSelectOption<SleepQuality>(
              value: SleepQuality.good,
              label: 'Buena',
            ),
            FzSelectOption<SleepQuality>(
              value: SleepQuality.excellent,
              label: 'Excelente',
            ),
          ],
          onChanged: (SleepQuality v) =>
              onChanged(habits.copyWith(sleepQuality: v)),
        ),
        const SizedBox(height: 20),

        // Horas de sueño (4 a 12 h, de 0.5 en 0.5).
        FzStepSliderField(
          label: 'Horas de Sueño',
          valueText: '${formatNumber(habits.sleepDuration)}h',
          value: habits.sleepDuration,
          min: 4,
          max: 12,
          step: 0.5,
          onChanged: (double v) =>
              onChanged(habits.copyWith(sleepDuration: v)),
        ),
        // 16 + los 4 px de aire que ya tiene el slider debajo = 20.
        const SizedBox(height: 16),

        // Nivel de actividad diaria.
        const FzLabel('Nivel de Actividad Diaria'),
        const SizedBox(height: 6),
        FzSelect<ActivityLevel>(
          value: habits.activityLevel,
          options: const <FzSelectOption<ActivityLevel>>[
            FzSelectOption<ActivityLevel>(
              value: ActivityLevel.sedentary,
              label: 'Sedentario',
            ),
            FzSelectOption<ActivityLevel>(
              value: ActivityLevel.light,
              label: 'Ligera',
            ),
            FzSelectOption<ActivityLevel>(
              value: ActivityLevel.moderate,
              label: 'Moderada',
            ),
            FzSelectOption<ActivityLevel>(
              value: ActivityLevel.active,
              label: 'Activa',
            ),
            FzSelectOption<ActivityLevel>(
              value: ActivityLevel.veryActive,
              label: 'Muy Activa',
            ),
          ],
          onChanged: (ActivityLevel v) =>
              onChanged(habits.copyWith(activityLevel: v)),
        ),
      ],
    );
  }
}