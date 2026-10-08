import 'package:flutter/material.dart';

import '../models/plan.dart';

const List<Plan> kPlans = <Plan>[
  Plan(
    id: PlanId.free,
    icon: Icons.fitness_center,
    name: 'Plan Gratuito',
    price: null,
    priceLabel: 'Gratis',
    priceSub: '3 días de prueba',
    badge: '3 días gratis',
    badgeStyle: PlanBadgeStyle.neutral,
    description:
        'Conoce FitZone, configura tu perfil y descubre las funciones principales sin compromiso.',
    cta: 'Comenzar gratis',
    highlighted: false,
    features: <String>[
      'Acceso completo 3 días',
      'Configura tu perfil fitness',
      'Explorar la plataforma',
    ],
  ),
  Plan(
    id: PlanId.monthly,
    icon: Icons.bolt,
    name: 'Plan Mensual',
    price: 29,
    priceLabel: '\$29',
    priceSub: 'por mes',
    badge: null,
    badgeStyle: PlanBadgeStyle.neutral,
    description:
        'Acceso completo a FitZone con entrenador personal y seguimiento personalizado.',
    cta: 'Elegir mensual',
    highlighted: false,
    features: <String>[
      'Entrenador personal asignado',
      'Plan nutricional incluido',
      'Seguimiento semanal',
    ],
  ),
  Plan(
    id: PlanId.annual,
    icon: Icons.emoji_events,
    name: 'Plan Anual',
    price: 199,
    priceLabel: '\$199',
    priceSub: 'por año',
    badge: 'Ahorra 43%',
    badgeStyle: PlanBadgeStyle.premium,
    description:
        'La experiencia completa de FitZone a lo largo del año. El mejor precio disponible.',
    cta: 'Elegir anual',
    highlighted: true,
    features: <String>[
      'Todo lo del plan mensual',
      'Precio equivalente a \$16.6/mes',
      'Soporte VIP prioritario',
    ],
  ),
];