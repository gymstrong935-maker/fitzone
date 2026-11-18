import 'package:flutter/material.dart';

import '../data/goals_data.dart';
import '../models/goal.dart';
import '../widgets/goal_card.dart';
import '../widgets/step_header.dart';

/// Paso "¿Qué quieres lograr?": elegir el objetivo principal.
class GoalsStep extends StatelessWidget {
  const GoalsStep({super.key, required this.selected, required this.onSelect});

  final Goal? selected;
  final ValueChanged<Goal> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const StepHeader(
          icon: Icons.track_changes_rounded,
          title: '¿Qué quieres lograr?',
          subtitle: 'Selecciona tu objetivo principal',
          teal: true,
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < kGoals.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          GoalCard(
            option: kGoals[i],
            isSelected: selected == kGoals[i].id,
            onTap: () => onSelect(kGoals[i].id),
          ),
        ],
      ],
    );
  }
}