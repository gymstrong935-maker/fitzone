import TrainingFrequency from '../models/TrainingFrequency.js';

export const crearFrecuencia = async (req, res) => {
  try { res.status(201).json(await TrainingFrequency.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerFrecuenciaPorUsuario = async (req, res) => {
  try { res.json(await TrainingFrequency.find({ usuarioId: req.params.usuarioId })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};