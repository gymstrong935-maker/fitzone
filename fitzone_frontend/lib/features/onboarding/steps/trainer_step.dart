import 'package:flutter/material.dart';

import '../data/trainers_data.dart';
import '../data/trainers_repository.dart';
import '../models/trainer.dart';
import '../widgets/step_header.dart';
import '../widgets/trainer_benefits_panel.dart';
import '../widgets/trainer_card.dart';
import '../../../core/utils/format.dart';

/// Paso 1 (solo planes mensual y anual): elegir entrenador.
class TrainerStep extends StatelessWidget {
  const TrainerStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final Trainer? selected;
  final ValueChanged<Trainer> onSelect;

  @override
  Widget build(BuildContext context) {
    // Entrenadores reales del servidor (o los del diseño si no hay conexión).
    final List<Trainer> trainers = TrainersRepository.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const StepHeader(
          icon: Icons.fitness_center_rounded,
          title: 'Selecciona tu Entrenador',
          subtitle: 'Elige al profesional que mejor se adapte a ti',
        ),
        const SizedBox(height: 24),
        const TrainerBenefitsPanel(benefits: kTrainerBenefits),
        const SizedBox(height: 20),
        // La lista vive dentro del scroll de la página (sin scroll anidado) y en
        // pantallas anchas se reparte en dos columnas.
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final bool twoColumns = c.maxWidth >= 560 && trainers.length > 1;

            Widget card(Trainer trainer) => TrainerCard(
                  trainer: trainer,
                  isSelected: selected?.id == trainer.id,
                  onTap: () => onSelect(trainer),
                );

            if (!twoColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < trainers.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 12),
                    card(trainers[i]),
                  ],
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < trainers.length; i += 2) ...<Widget>[
                  if (i > 0) const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(child: card(trainers[i])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < trainers.length
                              ? card(trainers[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
