import TrainingFrequency from '../models/TrainingFrequency.js';

const sinUndefined = (obj) =>
  Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== undefined));

export const crearFrecuencia = async (req, res) => {
  try {
    const {
      usuarioId, diasPorSemana, diasPreferidos, horarioPreferido,
      duracionSesionMinutos, nivelActividad
    } = req.body;

    // Una frecuencia por usuario: si ya existe se actualiza
    const frecuencia = await TrainingFrequency.findOneAndUpdate(
      { usuarioId },
      {
        $set: sinUndefined({
          usuarioId, diasPorSemana, diasPreferidos, horarioPreferido,
          duracionSesionMinutos, nivelActividad
        })
      },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    res.status(201).json(frecuencia);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const obtenerFrecuenciaPorUsuario = async (req, res) => {
  try { res.json(await TrainingFrequency.find({ usuarioId: req.params.usuarioId })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};