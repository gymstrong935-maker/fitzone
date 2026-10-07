import PhysicalMeasurement from '../models/PhysicalMeasurement.js';

export const crearMedicion = async (req, res) => {
  try { res.status(201).json(await PhysicalMeasurement.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerMedicionesPorUsuario = async (req, res) => {
  try { res.json(await PhysicalMeasurement.find({ usuarioId: req.params.usuarioId }).sort({ fecha: -1 })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};