import 'package:flutter/material.dart';

import '../data/experience_levels_data.dart';
import '../models/experience_level.dart';
import '../widgets/experience_card.dart';
import '../widgets/step_header.dart';

/// Paso "Nivel de Experiencia".
class ExperienceStep extends StatelessWidget {
  const ExperienceStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ExperienceLevel? selected;
  final ValueChanged<ExperienceLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const StepHeader(
          icon: Icons.workspace_premium_outlined,
          title: 'Nivel de Experiencia',
          subtitle: '¿Cuánto tiempo llevas entrenando?',
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < kExperienceLevels.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          ExperienceCard(
            option: kExperienceLevels[i],
            isSelected: selected == kExperienceLevels[i].id,
            onTap: () => onSelect(kExperienceLevels[i].id),
          ),
        ],
      ],
    );
  }
}