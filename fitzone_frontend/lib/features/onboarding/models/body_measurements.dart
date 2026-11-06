enum SkinfoldSite {
  triceps,
  subscapular,
  chest,
  abdominal,
  thigh,
  suprailiac,
  midaxillary,
}
 
/// Circunferencias, en cm.
enum CircumferenceSite { arm, chest, waist, hip, thigh, calf }
 
/// Mediciones corporales (todas opcionales).
class BodyMeasurements {
  const BodyMeasurements({
    this.skinfolds = const <SkinfoldSite, double>{},
    this.circumferences = const <CircumferenceSite, double>{},
  });
 
  final Map<SkinfoldSite, double> skinfolds;
  final Map<CircumferenceSite, double> circumferences;
 
  bool get isEmpty => skinfolds.isEmpty && circumferences.isEmpty;
 
  /// Rangos razonables (mín, máx) en cm. Fuera de ellos el dato se rechaza.
  static const Map<CircumferenceSite, (double, double)> circumferenceRanges =
      <CircumferenceSite, (double, double)>{
    CircumferenceSite.arm: (15.0, 70.0),
    CircumferenceSite.chest: (60.0, 200.0),
    CircumferenceSite.waist: (40.0, 200.0),
    CircumferenceSite.hip: (50.0, 200.0),
    CircumferenceSite.thigh: (30.0, 110.0),
    CircumferenceSite.calf: (20.0, 70.0),
  };
 
  /// Rangos razonables (mín, máx) en mm para cada pliegue.
  static const Map<SkinfoldSite, (double, double)> skinfoldRanges =
      <SkinfoldSite, (double, double)>{
    SkinfoldSite.triceps: (2.0, 60.0),
    SkinfoldSite.subscapular: (2.0, 60.0),
    SkinfoldSite.chest: (2.0, 60.0),
    SkinfoldSite.abdominal: (2.0, 80.0),
    SkinfoldSite.thigh: (2.0, 80.0),
    SkinfoldSite.suprailiac: (2.0, 70.0),
    SkinfoldSite.midaxillary: (2.0, 60.0),
  };
 
  static const Map<SkinfoldSite, String> _skinfoldLabels =
      <SkinfoldSite, String>{
    SkinfoldSite.triceps: 'tríceps',
    SkinfoldSite.subscapular: 'subescapular',
    SkinfoldSite.chest: 'pecho',
    SkinfoldSite.abdominal: 'abdominal',
    SkinfoldSite.thigh: 'muslo',
    SkinfoldSite.suprailiac: 'suprailíaco',
    SkinfoldSite.midaxillary: 'axilar medio',
  };
 
  static String _fmt(double v) => v.toInt().toString();
 
  /// `true` si hay una circunferencia escrita pero fuera de rango.
  bool circumferenceOutOfRange(CircumferenceSite site) {
    final double? v = circumferences[site];
    if (v == null || v <= 0) return false;
    final (double min, double max) = circumferenceRanges[site]!;
    return v < min || v > max;
  }
 
  /// `true` si hay un pliegue escrito pero fuera de rango (es opcional: vacío es válido).
  bool skinfoldOutOfRange(SkinfoldSite site) {
    final double? v = skinfolds[site];
    if (v == null) return false;
    final (double min, double max) = skinfoldRanges[site]!;
    return v < min || v > max;
  }
 
  /// Lo que impide continuar: circunferencias vacías o fuera de rango, y
  /// pliegues (opcionales) escritos con un valor imposible.
  List<String> get missing => <String>[
        for (final MapEntry<CircumferenceSite, String> e in _labels.entries)
          if ((circumferences[e.key] ?? 0) <= 0)
            e.value
          else if (circumferenceOutOfRange(e.key))
            '${e.value} (${_fmt(circumferenceRanges[e.key]!.$1)}–${_fmt(circumferenceRanges[e.key]!.$2)} cm)',
        for (final MapEntry<SkinfoldSite, String> e in _skinfoldLabels.entries)
          if (skinfoldOutOfRange(e.key))
            'pliegue ${e.value} (${_fmt(skinfoldRanges[e.key]!.$1)}–${_fmt(skinfoldRanges[e.key]!.$2)} mm)',
      ];
 
  bool get isComplete => missing.isEmpty;
 
  static const Map<CircumferenceSite, String> _labels = <CircumferenceSite, String>{
    CircumferenceSite.arm: 'brazo',
    CircumferenceSite.chest: 'pecho',
    CircumferenceSite.waist: 'cintura',
    CircumferenceSite.hip: 'cadera',
    CircumferenceSite.thigh: 'muslo',
    CircumferenceSite.calf: 'pantorrilla',
  };
 
  /// Devuelve una copia con la medida cambiada; `null` la elimina.
  BodyMeasurements withSkinfold(SkinfoldSite site, double? value) {
    final Map<SkinfoldSite, double> next =
        Map<SkinfoldSite, double>.of(skinfolds);
    if (value == null) {
      next.remove(site);
    } else {
      next[site] = value;
    }
    return BodyMeasurements(skinfolds: next, circumferences: circumferences);
  }
 
  BodyMeasurements withCircumference(CircumferenceSite site, double? value) {
    final Map<CircumferenceSite, double> next =
        Map<CircumferenceSite, double>.of(circumferences);
    if (value == null) {
      next.remove(site);
    } else {
      next[site] = value;
    }
    return BodyMeasurements(skinfolds: skinfolds, circumferences: next);
  }
}