import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../data/trainers_data.dart';
import '../models/trainer.dart';
import '../widgets/step_header.dart';
import '../widgets/trainer_benefits_panel.dart';
import '../widgets/trainer_card.dart';

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
    // La lista ocupa como máximo el 40 % del alto de la pantalla y hace scroll
    // por dentro (igual que max-h-[40vh] del diseño).
    final double maxListHeight = MediaQuery.sizeOf(context).height * 0.4;

    final ScrollBehavior listBehavior =
        ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
      dragDevices: <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      },
    );

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
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child: ScrollConfiguration(
            behavior: listBehavior,
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: kTrainers.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Trainer trainer = kTrainers[index];
                return TrainerCard(
                  trainer: trainer,
                  isSelected: selected?.id == trainer.id,
                  onTap: () => onSelect(trainer),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}