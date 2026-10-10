import '../../../core/services/backend_models.dart';
import '../../../core/utils/format.dart';
import '../models/plan.dart';
import 'plans_data.dart';

/// Qué plan del diseño corresponde a un plan del backend.
PlanId? planIdFor(BackendPlan plan) {
  if (plan.esGratuito) return PlanId.free;

  final String name = plan.nombre.toLowerCase();
  if (name.contains('anual')) return PlanId.annual;
  if (name.contains('mensual')) return PlanId.monthly;

  if (plan.duracionDias >= 300) return PlanId.annual;
  if (plan.duracionDias >= 25) return PlanId.monthly;
  return null;
}

/// Tarjetas del diseño con precios, badges y beneficios del servidor.
List<Plan> mergePlansWithBackend(List<BackendPlan> backend) {
  final Map<PlanId, BackendPlan> byId = <PlanId, BackendPlan>{};
  for (final BackendPlan b in backend) {
    final PlanId? id = planIdFor(b);
    if (id != null) byId.putIfAbsent(id, () => b);
  }

  return <Plan>[
    for (final Plan base in kPlans) _merge(base, byId[base.id], byId),
  ];
}

Plan _merge(Plan base, BackendPlan? b, Map<PlanId, BackendPlan> all) {
  if (b == null) return base;

  String priceLabel = base.priceLabel;
  String priceSub = base.priceSub;
  String? badge = base.badge;
  int? price = base.price;

  if (base.id == PlanId.free) {
    priceLabel = 'Gratis';
    priceSub = '${b.duracionDias} días de prueba';
    badge = '${b.duracionDias} días gratis';
    price = null;
  } else if (base.id == PlanId.monthly) {
    priceLabel = formatCop(b.precio);
    priceSub = 'por mes';
    price = b.precio.round();
  } else if (base.id == PlanId.annual) {
    priceLabel = formatCop(b.precio);
    priceSub = 'por año';
    price = b.precio.round();

    final BackendPlan? monthly = all[PlanId.monthly];
    if (monthly != null && monthly.precio > 0) {
      final int saving =
          ((1 - b.precio / (monthly.precio * 12)) * 100).round();
      badge = saving > 0 ? 'Ahorra $saving%' : null;
    }
  }

  return Plan(
    id: base.id,
    icon: base.icon,
    name: base.name,
    price: price,
    priceLabel: priceLabel,
    priceSub: priceSub,
    badge: badge,
    badgeStyle: base.badgeStyle,
    description: base.description,
    cta: base.cta,
    highlighted: base.highlighted,
    features: b.beneficios.isEmpty
        ? base.features
        : b.beneficios.take(4).toList(),
    backendId: b.id,
  );
}