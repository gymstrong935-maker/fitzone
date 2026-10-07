import Plan from '../models/Plan.js';

export const crearPlan = async (req, res) => {
  try {
    res.status(201).json(await Plan.create(req.body));
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ mensaje: 'Ya existe un plan con ese nombre' });
    res.status(500).json({ error: e.message });
  }
};

export const obtenerPlanes = async (req, res) => {
  try { res.json(await Plan.find()); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const eliminarPlan = async (req, res) => {
  try {
    const plan = await Plan.findByIdAndDelete(req.params.id);
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });
    res.json({ mensaje: 'Plan eliminado' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};