import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/measurements_service.dart';
import '../../onboarding/models/body_measurements.dart';
import '../../onboarding/models/onboarding_data.dart';
import '../../onboarding/models/personal_info.dart';

/// 75.0 -> "75", 74.5 -> "74.5", 74.46 -> "74.5"
String formatStat(double value) {
  final double rounded = double.parse(value.toStringAsFixed(1));
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

/// +1.5 -> "+1.5", -2 -> "-2", 0 -> "0"
String formatSigned(double value) {
  final String body = formatStat(value.abs());
  if (body == '0') return '0';
  return value > 0 ? '+$body' : '-$body';
}

// ═══════════════════════════════════════════════════════════════════════════
// Peso
// ═══════════════════════════════════════════════════════════════════════════

class WeightPoint {
  const WeightPoint(this.week, this.kg);

  /// Etiqueta del eje X (fecha de la medición, p. ej. "12/10").
  final String week;
  final double kg;
}

/// Cuántas mediciones se dibujan en la gráfica de peso.
const int kWeightWindow = 6;

/// Las últimas [kWeightWindow] mediciones, de la más vieja a la más nueva.
List<BodyRecord> weightWindow(List<BodyRecord> records) {
  if (records.length <= kWeightWindow) return records;
  return records.sublist(records.length - kWeightWindow);
}

List<WeightPoint> buildWeightPoints(List<BodyRecord> records) {
  return <WeightPoint>[
    for (final BodyRecord r in weightWindow(records))
      WeightPoint('${r.date.day}/${r.date.month}', r.kg),
  ];
}

/// Cambio de peso entre la primera y la última medición de la gráfica.
double weightChange(List<BodyRecord> records) {
  final List<BodyRecord> window = weightWindow(records);
  if (window.length < 2) return 0;
  return window.last.kg - window.first.kg;
}

// ═══════════════════════════════════════════════════════════════════════════
// Actividad (minutos por día, lunes a domingo)
// ═══════════════════════════════════════════════════════════════════════════

class ActivityPoint {
  const ActivityPoint(this.day, this.minutes);

  final String day;
  final int minutes;
}

const List<String> _weekLetters = <String>['L', 'M', 'X', 'J', 'V', 'S', 'D'];

List<ActivityPoint> buildActivity(List<int> minutesByWeekday) {
  return <ActivityPoint>[
    for (int i = 0; i < 7; i++)
      ActivityPoint(
        _weekLetters[i],
        i < minutesByWeekday.length ? minutesByWeekday[i] : 0,
      ),
  ];
}

/// Cumplimiento semanal en % (0 a 100): sesiones hechas / meta semanal.
int compliancePercent(int sessions, int weeklyGoal) {
  if (weeklyGoal <= 0) return 0;
  return math.min(100, (sessions / weeklyGoal * 100).round());
}

// ═══════════════════════════════════════════════════════════════════════════
// Circunferencias
// ═══════════════════════════════════════════════════════════════════════════

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

  /// Valor de la medición anterior (`null` si es la primera).
  final double? prev;

  /// Valor que representa el 100 % de la barra.
  final double maxValue;

  /// `true` si subir esta medida es bueno (brazo, pecho, muslo).
  final bool positive;
  final String unit;

  bool get hasPrev => prev != null;
  double get diff => hasPrev ? current - prev! : 0;

  /// Casi sin cambio (menos de 0.05 cm) o sin medición anterior.
  bool get isNeutral => !hasPrev || diff.abs() < 0.05;
  bool get isGood => !isNeutral && (positive ? diff > 0 : diff < 0);
  double get fraction => (current / maxValue).clamp(0.0, 1.0).toDouble();
}

class _SiteSpec {
  const _SiteSpec(this.key, this.label, this.maxValue, this.positive);

  final String key;
  final String label;
  final double maxValue;
  final bool positive;
}

const List<_SiteSpec> _sites = <_SiteSpec>[
  _SiteSpec('brazo', 'Brazo', 60, true),
  _SiteSpec('pecho', 'Pecho', 140, true),
  _SiteSpec('cintura', 'Cintura', 130, false),
  _SiteSpec('cadera', 'Cadera', 150, false),
  _SiteSpec('muslo', 'Muslo', 90, true),
  _SiteSpec('pantorrilla', 'Pantorrilla', 60, true),
];

/// Medidas de la última medición comparadas con la anterior que tuvo un
/// valor distinto (así un registro de peso no "borra" el cambio de cintura).
List<CircumferenceStat> buildCircumferences(List<BodyRecord> records) {
  if (records.isEmpty) return const <CircumferenceStat>[];
  final BodyRecord latest = records.last;
  final List<CircumferenceStat> result = <CircumferenceStat>[];

  for (final _SiteSpec site in _sites) {
    final double? current = latest.circumferences[site.key];
    if (current == null) continue;

    double? prev;
    for (int i = records.length - 2; i >= 0; i--) {
      final double? v = records[i].circumferences[site.key];
      if (v != null && (v - current).abs() >= 0.05) {
        prev = v;
        break;
      }
    }
    // Hubo más de una medición pero este valor nunca cambió: "sin cambios".
    if (prev == null && records.length > 1) prev = current;

    result.add(
      CircumferenceStat(
        part: site.label,
        current: current,
        prev: prev,
        maxValue: site.maxValue,
        positive: site.positive,
      ),
    );
  }
  return result;
}

// ═══════════════════════════════════════════════════════════════════════════
// Composición corporal
// ═══════════════════════════════════════════════════════════════════════════

/// Medición construida con lo que la persona declaró al registrarse (se usa
/// mientras el servidor no tenga ninguna).
BodyRecord recordFromOnboarding(OnboardingData data, DateTime date) {
  final PersonalInfo p = data.personalInfo;

  const Map<CircumferenceSite, String> circumferenceKeys =
      <CircumferenceSite, String>{
    CircumferenceSite.arm: 'brazo',
    CircumferenceSite.chest: 'pecho',
    CircumferenceSite.waist: 'cintura',
    CircumferenceSite.hip: 'cadera',
    CircumferenceSite.thigh: 'muslo',
    CircumferenceSite.calf: 'pantorrilla',
  };
  const Map<SkinfoldSite, String> skinfoldKeys = <SkinfoldSite, String>{
    SkinfoldSite.triceps: 'triceps',
    SkinfoldSite.subscapular: 'subescapular',
    SkinfoldSite.chest: 'pecho',
    SkinfoldSite.abdominal: 'abdominal',
    SkinfoldSite.thigh: 'muslo',
    SkinfoldSite.suprailiac: 'suprailiaco',
    SkinfoldSite.midaxillary: 'axilarMedio',
  };

  final Map<String, double> circumferences = <String, double>{};
  data.bodyMeasurements.circumferences
      .forEach((CircumferenceSite site, double v) {
    final String? key = circumferenceKeys[site];
    if (key != null && v > 0) circumferences[key] = v;
  });

  final Map<String, double> skinfolds = <String, double>{};
  data.bodyMeasurements.skinfolds.forEach((SkinfoldSite site, double v) {
    final String? key = skinfoldKeys[site];
    if (key != null && v > 0) skinfolds[key] = v;
  });

  return BodyRecord(
    date: date,
    kg: p.weightKg,
    heightM: p.height / 100,
    circumferences: circumferences,
    skinfolds: skinfolds,
    usesPounds: p.weightUnit == WeightUnit.lb,
  );
}

/// Porcentaje de grasa corporal **estimado**.
///
/// · Con los 7 pliegues cutáneos: Jackson-Pollock (7 sitios) + Siri.
/// · Si no: fórmula de Deurenberg (IMC, edad y sexo).
double estimateBodyFat(
  BodyRecord r, {
  required int age,
  required Gender gender,
}) {
  final bool hasAllSkinfolds =
      kSkinfoldKeys.every((String k) => (r.skinfolds[k] ?? 0) > 0);

  double result;
  if (hasAllSkinfolds) {
    double sum = 0;
    for (final String k in kSkinfoldKeys) {
      sum += r.skinfolds[k] ?? 0;
    }

    double fatFor(bool male) {
      final double density = male
          ? 1.112 - 0.00043499 * sum + 0.00000055 * sum * sum - 0.00028826 * age
          : 1.097 - 0.00046971 * sum + 0.00000056 * sum * sum - 0.00012828 * age;
      return 495 / density - 450;
    }

    switch (gender) {
      case Gender.male:
        result = fatFor(true);
      case Gender.female:
        result = fatFor(false);
      case Gender.other:
        result = (fatFor(true) + fatFor(false)) / 2;
    }
  } else {
    // Deurenberg: 1.20·IMC + 0.23·edad − 10.8·sexo − 5.4 (hombre = 1, mujer = 0).
    double sex;
    switch (gender) {
      case Gender.male:
        sex = 1;
      case Gender.female:
        sex = 0;
      case Gender.other:
        sex = 0.5;
    }
    result = 1.20 * r.bmi + 0.23 * age - 10.8 * sex - 5.4;
  }

  return result.clamp(3.0, 60.0).toDouble();
}

String bmiCategory(double bmi) {
  if (bmi <= 0) return '—';
  if (bmi < 18.5) return 'Bajo peso';
  if (bmi < 25) return 'Saludable';
  if (bmi < 30) return 'Sobrepeso';
  return 'Obesidad';
}

// ═══════════════════════════════════════════════════════════════════════════
// Indicadores (KPIs)
// ═══════════════════════════════════════════════════════════════════════════

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

bool? _direction(double change) {
  if (change.abs() < 0.05) return null;
  return change > 0;
}

String _deltaText(double change, String unit, {required bool hasPrevious}) {
  if (!hasPrevious) return 'Inicial';
  if (change.abs() < 0.05) return 'Sin cambios';
  return '${formatSigned(change)} $unit';
}

/// Los 4 indicadores de arriba, calculados con las mediciones reales.
List<StatKpi> buildKpis(
  List<BodyRecord> records, {
  required int age,
  required Gender gender,
}) {
  if (records.isEmpty) return const <StatKpi>[];

  final List<BodyRecord> window = weightWindow(records);
  final BodyRecord latest = records.last;
  final BodyRecord first = window.first;
  final bool hasPrevious = window.length > 1;

  final double weightDiff = latest.kg - first.kg;

  final double fatNow = estimateBodyFat(latest, age: age, gender: gender);
  final double fatThen = estimateBodyFat(first, age: age, gender: gender);
  final double fatDiff = fatNow - fatThen;

  final double leanNow = latest.kg * (1 - fatNow / 100);
  final double leanThen = first.kg * (1 - fatThen / 100);
  final double leanDiff = leanNow - leanThen;

  return <StatKpi>[
    StatKpi(
      label: 'Peso Actual',
      value: '${formatStat(latest.kg)} kg',
      delta: _deltaText(weightDiff, 'kg', hasPrevious: hasPrevious),
      icon: Icons.monitor_weight_outlined,
      color: const Color(0xFF06B6D4),
      up: hasPrevious ? _direction(weightDiff) : null,
    ),
    StatKpi(
      label: 'IMC',
      value: latest.bmi.toStringAsFixed(1),
      delta: bmiCategory(latest.bmi),
      icon: Icons.monitor_heart_outlined,
      color: const Color(0xFF14B8A6),
      up: null,
    ),
    StatKpi(
      label: 'Masa Magra (est.)',
      value: '${formatStat(leanNow)} kg',
      delta: _deltaText(leanDiff, 'kg', hasPrevious: hasPrevious),
      icon: Icons.bolt_rounded,
      color: const Color(0xFFA78BFA),
      up: hasPrevious ? _direction(leanDiff) : null,
    ),
    StatKpi(
      label: 'Grasa Corp. (est.)',
      value: '${formatStat(fatNow)}%',
      delta: _deltaText(fatDiff, '%', hasPrevious: hasPrevious),
      icon: Icons.trending_down_rounded,
      color: const Color(0xFFF97316),
      up: hasPrevious ? _direction(fatDiff) : null,
    ),
  ];
}
