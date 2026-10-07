import TrainingPeriod from '../models/TrainingPeriod.js';

export const crearPeriodo = async (req, res) => {
  try { res.status(201).json(await TrainingPeriod.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerPeriodosPorUsuario = async (req, res) => {
  try { res.json(await TrainingPeriod.find({ usuarioId: req.params.usuarioId })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};