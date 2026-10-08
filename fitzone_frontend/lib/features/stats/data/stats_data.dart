import 'package:flutter/material.dart';

/// 75.0 -> "75", 74.5 -> "74.5"
String formatStat(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

// ── Peso (últimas 6 semanas) ────────────────────────────────────────────────

class WeightPoint {
  const WeightPoint(this.week, this.kg);

  final String week;
  final double kg;
}

const List<WeightPoint> kWeightData = <WeightPoint>[
  WeightPoint('S1', 75.0),
  WeightPoint('S2', 74.5),
  WeightPoint('S3', 74.2),
  WeightPoint('S4', 73.8),
  WeightPoint('S5', 73.5),
  WeightPoint('S6', 73.0),
];

// ── Actividad (minutos por día, lunes a domingo) ────────────────────────────

class ActivityPoint {
  const ActivityPoint(this.day, this.minutes);

  final String day;
  final int minutes;
}

const List<ActivityPoint> kActivityData = <ActivityPoint>[
  ActivityPoint('L', 45),
  ActivityPoint('M', 60),
  ActivityPoint('X', 0),
  ActivityPoint('J', 50),
  ActivityPoint('V', 55),
  ActivityPoint('S', 30),
  ActivityPoint('D', 0),
];

// ── Circunferencias ─────────────────────────────────────────────────────────

class CircumferenceStat {
  const CircumferenceStat({
    required this.part,
    required this.current,
    required this.prev,
    required this.maxValue,
    required this.positive,
    this.unit = 'cm',
  });

  final String part;
  final double current;
  final double prev;

  /// Valor que representa el 100 % de la barra.
  final double maxValue;

  /// `true` si subir esta medida es bueno (brazo, pecho, muslo).
  final bool positive;
  final String unit;

  double get diff => current - prev;
  bool get isGood => positive ? diff > 0 : diff < 0;
  double get fraction => current / maxValue;
}

const List<CircumferenceStat> kCircumferences = <CircumferenceStat>[
  CircumferenceStat(
    part: 'Brazo',
    current: 38,
    prev: 36.5,
    maxValue: 70,
    positive: true,
  ),
  CircumferenceStat(
    part: 'Pecho',
    current: 102,
    prev: 100,
    maxValue: 120,
    positive: true,
  ),
  CircumferenceStat(
    part: 'Cintura',
    current: 82,
    prev: 85,
    maxValue: 70,
    positive: false,
  ),
  CircumferenceStat(
    part: 'Cadera',
    current: 98,
    prev: 100,
    maxValue: 110,
    positive: false,
  ),
  CircumferenceStat(
    part: 'Muslo',
    current: 58,
    prev: 57,
    maxValue: 70,
    positive: true,
  ),
];

// ── Indicadores (KPIs) ──────────────────────────────────────────────────────

class StatKpi {
  const StatKpi({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
    required this.up,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  /// `true` = sube (verde), `false` = baja (cian), `null` = neutral.
  final bool? up;
}

const List<StatKpi> kStatKpis = <StatKpi>[
  StatKpi(
    label: 'Peso Actual',
    value: '73 kg',
    delta: '-2 kg',
    icon: Icons.monitor_weight_outlined,
    color: Color(0xFF06B6D4),
    up: false,
  ),
  StatKpi(
    label: 'IMC',
    value: '23.4',
    delta: 'Saludable',
    icon: Icons.monitor_heart_outlined,
    color: Color(0xFF14B8A6),
    up: null,
  ),
  StatKpi(
    label: 'Masa Muscular',
    value: '62 kg',
    delta: '+1.5 kg',
    icon: Icons.bolt_rounded,
    color: Color(0xFFA78BFA),
    up: true,
  ),
  StatKpi(
    label: 'Grasa Corp.',
    value: '15%',
    delta: '-3%',
    icon: Icons.trending_down_rounded,
    color: Color(0xFFF97316),
    up: false,
  ),
];