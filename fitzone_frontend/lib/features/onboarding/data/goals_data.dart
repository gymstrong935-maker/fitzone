import 'package:flutter/material.dart';

import '../models/goal.dart';

const List<GoalOption> kGoals = <GoalOption>[
  GoalOption(
    id: Goal.loseWeight,
    title: 'Perder Peso',
    description: 'Reducir grasa corporal y mejorar composición',
    icon: '🔥',
    from: Color(0xFFF97316), // naranja
    to: Color(0xFFEF4444), // rojo
  ),
  GoalOption(
    id: Goal.gainMuscle,
    title: 'Ganar Masa Muscular',
    description: 'Hipertrofia y desarrollo muscular',
    icon: '💪',
    from: Color(0xFF3B82F6), // azul
    to: Color(0xFFA855F7), // morado
  ),
  GoalOption(
    id: Goal.improveEndurance,
    title: 'Mejorar Resistencia',
    description: 'Aumentar capacidad cardiovascular',
    icon: '🏃',
    from: Color(0xFF22C55E), // verde
    to: Color(0xFF14B8A6), // turquesa
  ),
  GoalOption(
    id: Goal.bodyRecomposition,
    title: 'Recomposición Corporal',
    description: 'Ganar músculo y perder grasa simultáneamente',
    icon: '⚡',
    from: Color(0xFF06B6D4), // cian
    to: Color(0xFF3B82F6), // azul
  ),
  GoalOption(
    id: Goal.athleticPerformance,
    title: 'Rendimiento Deportivo',
    description: 'Mejorar fuerza, velocidad y agilidad',
    icon: '🏆',
    from: Color(0xFFEAB308), // amarillo
    to: Color(0xFFF97316), // naranja
  ),
];