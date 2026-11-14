import Motivation from '../models/Motivation.js';

export const crearRegistroMotivacion = async (req, res) => {
  try { res.status(201).json(await Motivation.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerMotivacionPorUsuario = async (req, res) => {
  try { res.json(await Motivation.find({ usuarioId: req.params.usuarioId }).sort({ fecha: -1 })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};