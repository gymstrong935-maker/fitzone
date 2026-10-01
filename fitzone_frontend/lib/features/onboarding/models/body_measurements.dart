/// Pliegues cutáneos (plicometría), en mm.
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