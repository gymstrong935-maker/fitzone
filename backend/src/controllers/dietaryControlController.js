import mongoose from 'mongoose';
import DietaryControl from '../models/DietaryControl.js';

export const crearRegistroAlimentacion = async (req, res) => {
  try {
    const { usuarioId, fecha, comidas, aguaLitros } = req.body;
    const registro = await DietaryControl.create({ usuarioId, fecha, comidas, aguaLitros });
    res.status(201).json(registro);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const obtenerAlimentacionPorUsuario = async (req, res) => {
  try {
    const registros = await DietaryControl
      .find({ usuarioId: req.params.usuarioId })
      .sort({ fecha: -1 })
      .limit(300);

    res.json(registros);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const eliminarRegistroAlimentacion = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Registro no válido' });
    }

    const filtro = { _id: req.params.id };

    // Un usuario normal solo puede borrar sus propios registros
    if (req.usuario?.rol !== 'admin') {
      filtro.usuarioId = req.usuario.id;
    }

    const eliminado = await DietaryControl.findOneAndDelete(filtro);
    if (!eliminado) return res.status(404).json({ mensaje: 'Registro no encontrado' });

    res.json({ mensaje: 'Registro eliminado' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};