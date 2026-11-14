class Achievement {
  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.done,
    this.date,
    this.progress = 0,
  });

  final String title;
  final String description;

  /// Emoji del logro.
  final String icon;
  final bool done;

  /// Fecha en que se desbloqueó (solo si [done]).
  final String? date;

  /// Avance de 0 a 100 (solo si no está completado).
  final int progress;
}

const List<Achievement> kAchievements = <Achievement>[
  Achievement(
    title: 'Primera Semana',
    description: 'Completaste tu primera semana de entrenamiento',
    icon: '🎯',
    done: true,
    date: '10 Sep 2026',
    progress: 100,
  ),
  Achievement(
    title: 'Constancia',
    description: '7 días seguidos entrenando',
    icon: '🔥',
    done: true,
    date: '12 Sep 2026',
    progress: 100,
  ),
  Achievement(
    title: 'Fuerza Bruta',
    description: 'Levanta 100 kg en peso muerto',
    icon: '💪',
    done: false,
    progress: 85,
  ),
  Achievement(
    title: 'Maratonista',
    description: 'Corre 5 km sin parar',
    icon: '🏃',
    done: false,
    progress: 60,
  ),
  Achievement(
    title: 'Dedicación',
    description: '30 entrenamientos completados',
    icon: '🏆',
    done: false,
    progress: 40,
  ),
];