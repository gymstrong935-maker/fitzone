import 'package:flutter/material.dart';

enum PlanId { free, monthly, annual }

enum PlanBadgeStyle { neutral, premium }

class Plan {
  const Plan({
    required this.id,
    required this.icon,
    required this.name,
    required this.price,
    required this.priceLabel,
    required this.priceSub,
    required this.badge,
    required this.badgeStyle,
    required this.description,
    required this.cta,
    required this.highlighted,
    required this.features,
    this.backendId,
  });

  final PlanId id;
  final IconData icon;
  final String name;
  final int? price;
  final String priceLabel;
  final String priceSub;
  final String? badge;
  final PlanBadgeStyle badgeStyle;
  final String description;
  final String cta;
  final bool highlighted;
  final List<String> features;

  /// Id del plan en el backend (`null` si todavía no se cargó del servidor).
  final String? backendId;
}