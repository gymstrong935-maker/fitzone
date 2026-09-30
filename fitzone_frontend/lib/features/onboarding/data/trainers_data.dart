import '../models/trainer.dart';

const List<Trainer> kTrainers = <Trainer>[
  Trainer(
    id: 'trainer-1',
    name: 'Ana Martínez',
    photo:
        'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=400&h=400&fit=crop',
    specialty: 'Hipertrofia y Fuerza',
    experience: 8,
    certifications: <String>['NSCA-CPT', 'ISSA Bodybuilding', 'Nutrición Deportiva'],
    rating: 4.9,
    description:
        'Especialista en desarrollo muscular y programas de fuerza adaptados a cada nivel.',
    trainingType: 'Personalizado con énfasis en técnica y progresión',
    price: 89,
    priceDescription: '/mes',
    services: <String>[
      'Plan de entrenamiento personalizado',
      'Asesoría nutricional básica',
      'Seguimiento semanal',
      'Ajustes mensuales del plan',
      'Chat de soporte',
    ],
    level: TrainerLevel.premium,
  ),
  Trainer(
    id: 'trainer-2',
    name: 'Carlos Rodríguez',
    photo:
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&h=400&fit=crop',
    specialty: 'Recomposición Corporal',
    experience: 10,
    certifications: <String>['ACE', 'Precision Nutrition Level 2', 'NASM-PES'],
    rating: 4.8,
    description:
        'Experto en transformación física combinando entrenamiento y nutrición estratégica.',
    trainingType: 'Enfoque integral: entrenamiento + nutrición',
    price: 129,
    priceDescription: '/mes',
    services: <String>[
      'Plan de entrenamiento avanzado',
      'Plan nutricional completo',
      'Seguimiento diario',
      'Videollamadas semanales',
      'Ajustes constantes',
      'Soporte 24/7',
    ],
    level: TrainerLevel.elite,
  ),
  Trainer(
    id: 'trainer-3',
    name: 'Laura Sánchez',
    photo:
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&h=400&fit=crop',
    specialty: 'Resistencia y Atletismo',
    experience: 7,
    certifications: <String>['ACSM-CPT', 'Running Coach', 'Functional Training'],
    rating: 4.7,
    description:
        'Entrenadora de resistencia cardiovascular y preparación atlética de alto rendimiento.',
    trainingType: 'Entrenamiento funcional y deportivo',
    price: 79,
    priceDescription: '/mes',
    services: <String>[
      'Plan de entrenamiento funcional',
      'Rutinas de cardio personalizadas',
      'Seguimiento quincenal',
      'Consejos de recuperación',
    ],
    level: TrainerLevel.premium,
  ),
  Trainer(
    id: 'trainer-4',
    name: 'Miguel Torres',
    photo:
        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&h=400&fit=crop',
    specialty: 'Fuerza para Principiantes',
    experience: 5,
    certifications: <String>['ISSA-CPT', 'Corrective Exercise', 'TRX Certified'],
    rating: 4.9,
    description:
        'Dedicado a guiar principiantes con bases sólidas de técnica y seguridad.',
    trainingType: 'Progresión gradual con énfasis en fundamentos',
    price: 49,
    priceDescription: '/mes',
    services: <String>[
      'Plan básico de entrenamiento',
      'Videos de técnica',
      'Seguimiento mensual',
      'Email de soporte',
    ],
    level: TrainerLevel.standard,
  ),
  Trainer(
    id: 'trainer-5',
    name: 'Diana López',
    photo:
        'https://images.unsplash.com/photo-1607962837359-5e7e89f86776?w=400&h=400&fit=crop',
    specialty: 'Pérdida de Grasa y Tonificación',
    experience: 6,
    certifications: <String>['NASM-CPT', 'Weight Management', 'Group Fitness'],
    rating: 4.8,
    description:
        'Especialista en programas de definición muscular y pérdida de grasa sostenible.',
    trainingType: 'Combinación de HIIT y entrenamiento de fuerza',
    price: 69,
    priceDescription: '/mes',
    services: <String>[
      'Plan de tonificación',
      'Rutinas HIIT',
      'Guías de alimentación',
      'Seguimiento semanal',
      'Motivación constante',
    ],
    level: TrainerLevel.standard,
  ),
];

const List<TrainerBenefit> kTrainerBenefits = <TrainerBenefit>[
  TrainerBenefit(
    icon: '🎯',
    title: 'Mayor Personalización',
    description:
        'Plan 100% adaptado a tus necesidades, objetivos y condiciones específicas',
  ),
  TrainerBenefit(
    icon: '🛡️',
    title: 'Reducción de Lesiones',
    description:
        'Supervisión profesional que minimiza riesgos y corrige tu técnica',
  ),
  TrainerBenefit(
    icon: '📈',
    title: 'Mejor Progreso',
    description:
        'Resultados más rápidos y efectivos con seguimiento constante',
  ),
  TrainerBenefit(
    icon: '💼',
    title: 'Plan Profesional',
    description:
        'Programación científica basada en evidencia y experiencia certificada',
  ),
];