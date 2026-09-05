import PhysicalCondition from '../models/PhysicalCondition.js';
import Group from '../models/Group.js';

export const crearCondicion = async (req, res) => {
  try {
    const condicion = await PhysicalCondition.create(req.body);

    // Busca un grupo que coincida con el nivel del usuario y lo asigna
    const grupoDisponible = await Group.findOne({ nivel: condicion.nivel });

    if (grupoDisponible && !grupoDisponible.miembros.includes(condicion.usuarioId)) {
      grupoDisponible.miembros.push(condicion.usuarioId);
      await grupoDisponible.save();
    }

    res.status(201).json({
      condicion,
      grupoAsignado: grupoDisponible ? grupoDisponible.nombre : 'Sin grupo disponible para este nivel'
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const obtenerCondicionPorUsuario = async (req, res) => {
  try { res.json(await PhysicalCondition.find({ usuarioId: req.params.usuarioId })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};