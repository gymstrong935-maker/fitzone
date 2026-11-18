import '../models/body_measurements.dart';

/// Explicación de cómo tomar una medida.
class MeasureGuide {
  const MeasureGuide({
    required this.title,
    required this.where,
    required this.steps,
    required this.tip,
    required this.tool,
  });

  /// Nombre de la medida (p. ej. "Cintura").
  final String title;

  /// Dónde se mide, en una frase.
  final String where;

  /// Pasos, en orden.
  final List<String> steps;

  /// Consejo para que la medida sea fiable.
  final String tip;

  /// Qué se necesita ("Cinta métrica flexible" o "Plicómetro").
  final String tool;
}

const String _tape = 'Cinta métrica flexible';
const String _caliper = 'Plicómetro (calibrador de pliegues)';

const String _tapeTip =
    'Mide siempre el mismo lado del cuerpo, a la misma hora y sin ropa gruesa. '
    'La cinta debe quedar ajustada pero sin apretar la piel.';

const String _caliperTip =
    'Mide siempre el lado derecho. Repite 2 o 3 veces y usa el promedio. '
    'Si no tienes plicómetro, deja este campo vacío: es opcional.';

/// Guías de las circunferencias (cm).
const Map<CircumferenceSite, MeasureGuide> kCircumferenceGuides =
    <CircumferenceSite, MeasureGuide>{
  CircumferenceSite.arm: MeasureGuide(
    title: 'Brazo',
    tool: _tape,
    where: 'A la mitad entre el hombro y el codo.',
    steps: <String>[
      'Párate derecho con el brazo relajado a un lado del cuerpo.',
      'Busca el punto medio entre la punta del hombro y el codo.',
      'Rodea el brazo con la cinta en ese punto, paralela al suelo.',
      'Lee el número cuando la cinta toque la piel sin hundirla.',
    ],
    tip: _tapeTip,
  ),
  CircumferenceSite.chest: MeasureGuide(
    title: 'Pecho',
    tool: _tape,
    where: 'Alrededor del pecho, a la altura de los pezones.',
    steps: <String>[
      'Párate derecho con los brazos relajados a los lados.',
      'Pasa la cinta por debajo de las axilas y sobre los pezones.',
      'Comprueba que quede paralela al suelo en la espalda también.',
      'Respira normal y mide al soltar el aire, sin inflar el pecho.',
    ],
    tip: _tapeTip,
  ),
  CircumferenceSite.waist: MeasureGuide(
    title: 'Cintura',
    tool: _tape,
    where: 'En la parte más angosta del torso, entre las costillas y la cadera.',
    steps: <String>[
      'Párate derecho, relajado, con el abdomen suelto.',
      'Busca la zona más estrecha, normalmente 2 o 3 cm por encima del ombligo.',
      'Rodea la cintura con la cinta, paralela al suelo.',
      'Mide al terminar de soltar el aire, sin meter la barriga.',
    ],
    tip: _tapeTip,
  ),
  CircumferenceSite.hip: MeasureGuide(
    title: 'Cadera',
    tool: _tape,
    where: 'En la parte más ancha de los glúteos.',
    steps: <String>[
      'Párate con los pies juntos y el peso repartido en ambas piernas.',
      'Busca la zona más ancha de los glúteos, vista de lado.',
      'Rodea la cadera con la cinta, paralela al suelo.',
      'Lee la medida sin apretar.',
    ],
    tip: _tapeTip,
  ),
  CircumferenceSite.thigh: MeasureGuide(
    title: 'Muslo',
    tool: _tape,
    where: 'A la mitad entre la ingle y la rodilla.',
    steps: <String>[
      'Párate con el peso repartido y las piernas ligeramente separadas.',
      'Busca el punto medio entre el pliegue de la ingle y la parte de arriba de la rodilla.',
      'Rodea el muslo con la cinta en ese punto, paralela al suelo.',
      'Lee la medida sin apretar.',
    ],
    tip: _tapeTip,
  ),
  CircumferenceSite.calf: MeasureGuide(
    title: 'Pantorrilla',
    tool: _tape,
    where: 'En la parte más gruesa de la pantorrilla.',
    steps: <String>[
      'Párate con el peso repartido en ambos pies, o siéntate con la rodilla a 90°.',
      'Busca la parte más abultada de la pantorrilla.',
      'Rodea la pierna con la cinta, perpendicular a la pierna.',
      'Mueve la cinta arriba y abajo y quédate con el mayor valor.',
    ],
    tip: _tapeTip,
  ),
};

/// Guías de la plicometría (mm).
const Map<SkinfoldSite, MeasureGuide> kSkinfoldGuides =
    <SkinfoldSite, MeasureGuide>{
  SkinfoldSite.triceps: MeasureGuide(
    title: 'Tríceps',
    tool: _caliper,
    where: 'Parte de atrás del brazo, a la mitad entre el hombro y el codo.',
    steps: <String>[
      'Deja el brazo relajado, con la palma hacia el frente.',
      'Marca el punto medio entre la punta del hombro y el codo, por detrás.',
      'Pellizca la piel y la grasa en vertical, sin tomar músculo.',
      'Coloca el plicómetro 1 cm debajo de tus dedos y lee a los 2 segundos.',
    ],
    tip: _caliperTip,
  ),
  SkinfoldSite.subscapular: MeasureGuide(
    title: 'Subescapular',
    tool: _caliper,
    where: 'Justo debajo de la punta inferior del omóplato.',
    steps: <String>[
      'Con el brazo relajado, ubica la punta inferior del omóplato.',
      'Pellizca la piel 1 cm hacia abajo y hacia afuera, en diagonal (unos 45°).',
      'Sigue la línea natural de la piel, hacia el codo contrario.',
      'Coloca el plicómetro junto a tus dedos y lee a los 2 segundos.',
    ],
    tip: _caliperTip,
  ),
  SkinfoldSite.chest: MeasureGuide(
    title: 'Pecho',
    tool: _caliper,
    where: 'Entre la axila y el pezón.',
    steps: <String>[
      'Ubica el borde del pecho cerca de la axila y el pezón.',
      'Pellizca en diagonal, a la mitad entre ambos (hombres) o a un tercio de la axila (mujeres).',
      'Mantén el pliegue firme con los dedos.',
      'Coloca el plicómetro 1 cm debajo de tus dedos y lee a los 2 segundos.',
    ],
    tip: _caliperTip,
  ),
  SkinfoldSite.abdominal: MeasureGuide(
    title: 'Abdominal',
    tool: _caliper,
    where: 'Al lado del ombligo.',
    steps: <String>[
      'Párate relajado, sin contraer el abdomen.',
      'Ubica un punto a 2 cm a la derecha del ombligo.',
      'Pellizca en vertical, sin tomar músculo.',
      'Coloca el plicómetro 1 cm debajo de tus dedos y lee a los 2 segundos.',
    ],
    tip: _caliperTip,
  ),
  SkinfoldSite.thigh: MeasureGuide(
    title: 'Muslo',
    tool: _caliper,
    where: 'Frente del muslo, a la mitad entre la ingle y la rodilla.',
    steps: <String>[
      'Apoya el peso en la pierna contraria y relaja el muslo que vas a medir.',
      'Marca el punto medio entre el pliegue de la ingle y la rótula.',
      'Pellizca en vertical por la parte delantera del muslo.',
      'Coloca el plicómetro 1 cm debajo de tus dedos y lee a los 2 segundos.',
    ],
    tip: _caliperTip,
  ),
  SkinfoldSite.suprailiac: MeasureGuide(
    title: 'Suprailíaco',
    tool: _caliper,
    where: 'Justo encima del hueso de la cadera, en el costado.',
    steps: <String>[
      'Ubica la parte superior del hueso de la cadera (cresta ilíaca).',
      'Sube el dedo unos 2 cm sobre ese hueso, en la línea de la axila hacia abajo.',
      'Pellizca en diagonal, siguiendo la línea natural de la piel.',
      'Coloca el plicómetro 1 cm debajo de tus dedos y lee a los 2 segundos.',
    ],
    tip: _caliperTip,
  ),
  SkinfoldSite.midaxillary: MeasureGuide(
    title: 'Axilar medio',
    tool: _caliper,
    where: 'Costado del tronco, a la altura de la parte baja del esternón.',
    steps: <String>[
      'Levanta un poco el brazo para dejar libre el costado.',
      'Ubica la línea que baja desde la mitad de la axila, a la altura del final del esternón.',
      'Pellizca en vertical (o ligeramente horizontal) en ese punto.',
      'Coloca el plicómetro 1 cm debajo de tus dedos y lee a los 2 segundos.',
    ],
    tip: _caliperTip,
  ),
};
