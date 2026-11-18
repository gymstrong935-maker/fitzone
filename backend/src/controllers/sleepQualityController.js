import SleepQuality from '../models/SleepQuality.js';

export const crearRegistroSueno = async (req, res) => {
  try { res.status(201).json(await SleepQuality.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerSuenoPorUsuario = async (req, res) => {
  try { res.json(await SleepQuality.find({ usuarioId: req.params.usuarioId }).sort({ fecha: -1 })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};