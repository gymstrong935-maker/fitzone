import TrainingParameter from '../models/TrainingParameter.js';

export const crearParametro = async (req, res) => {
  try { res.status(201).json(await TrainingParameter.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerParametrosPorUsuario = async (req, res) => {
  try { res.json(await TrainingParameter.find({ usuarioId: req.params.usuarioId }).sort({ fecha: -1 })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};