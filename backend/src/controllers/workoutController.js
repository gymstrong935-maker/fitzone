import WorkoutSession from '../models/WorkoutSession.js';

export const crearSesion = async (req, res) => {
  try {
    const { usuarioId, clienteId, ...datos } = req.body;

    // Con clienteId, repetir el envío devuelve la misma sesión (sin duplicar)
    if (clienteId) {
      try {
        const sesion = await WorkoutSession.findOneAndUpdate(
          { usuarioId, clienteId },
          { $setOnInsert: datos },
          { new: true, upsert: true }
        );
        return res.status(201).json(sesion);
      } catch (error) {
        // Dos envíos simultáneos: gana uno y el otro recupera la sesión creada
        if (error.code === 11000) {
          const existente = await WorkoutSession.findOne({ usuarioId, clienteId });
          if (existente) return res.status(200).json(existente);
        }
        throw error;
      }
    }

    const sesion = await WorkoutSession.create({ usuarioId, ...datos });
    res.status(201).json(sesion);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const obtenerSesionesPorUsuario = async (req, res) => {
  try {
    const sesiones = await WorkoutSession
      .find({ usuarioId: req.params.usuarioId })
      .sort({ fecha: -1 })
      .limit(200);

    res.json(sesiones);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};