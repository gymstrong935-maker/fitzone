import DietaryControl from '../models/DietaryControl.js';

export const crearRegistroAlimentacion = async (req, res) => {
  try { res.status(201).json(await DietaryControl.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerAlimentacionPorUsuario = async (req, res) => {
  try { res.json(await DietaryControl.find({ usuarioId: req.params.usuarioId }).sort({ fecha: -1 })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};