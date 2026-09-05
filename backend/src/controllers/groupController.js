import Group from '../models/Group.js';

export const crearGrupo = async (req, res) => {
  try {
    res.status(201).json(await Group.create(req.body));
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ mensaje: 'Ya existe un grupo con ese nombre' });
    res.status(500).json({ error: e.message });
  }
};

export const obtenerGrupos = async (req, res) => {
  try { res.json(await Group.find()); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const eliminarGrupo = async (req, res) => {
  try {
    const grupo = await Group.findByIdAndDelete(req.params.id);
    if (!grupo) return res.status(404).json({ mensaje: 'Grupo no encontrado' });
    res.json({ mensaje: 'Grupo eliminado' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};