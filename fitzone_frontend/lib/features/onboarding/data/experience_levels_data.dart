import '../models/experience_level.dart';

const List<ExperienceOption> kExperienceLevels = <ExperienceOption>[
  ExperienceOption(
    id: ExperienceLevel.beginner,
    title: 'Principiante',
    description: 'Menos de 1 año de experiencia',
    reps: '8 reps',
    icon: '🌱',
  ),
  ExperienceOption(
    id: ExperienceLevel.intermediate,
    title: 'Intermedio',
    description: '1-3 años de experiencia constante',
    reps: '12 reps',
    icon: '📈',
  ),
  ExperienceOption(
    id: ExperienceLevel.advanced,
    title: 'Avanzado',
    description: 'Más de 3 años de experiencia',
    reps: '15+ reps',
    icon: '🔱',
  ),
];