import PhysicalCondition from '../models/PhysicalCondition.js';
import Group from '../models/Group.js';

const sinUndefined = (obj) =>
  Object.fromEntries(
    Object.entries(obj).filter(([, value]) => value !== undefined)
  );

export const crearCondicion = async (req, res) => {
  try {
    const {
      usuarioId,
      nivel,
      lesiones,
      restricciones,
      observacionesMedicas,
      valoraciones
    } = req.body;

    // Una condición física por usuario.
    // Si ya existe, se actualiza; si no existe, se crea.
    const condicion = await PhysicalCondition.findOneAndUpdate(
      { usuarioId },
      {
        $set: sinUndefined({
          usuarioId,
          nivel,
          lesiones,
          restricciones,
          observacionesMedicas,
          valoraciones
        })
      },
      {
        new: true,
        upsert: true,
        setDefaultsOnInsert: true
      }
    );

    // Busca un grupo compatible con el nivel del usuario.
    const grupoDisponible = condicion.nivel
      ? await Group.findOne({ nivel: condicion.nivel })
      : null;

    if (grupoDisponible) {
      const yaEsMiembro = grupoDisponible.miembros.some(
        (miembroId) =>
          miembroId.toString() === condicion.usuarioId.toString()
      );

      if (!yaEsMiembro) {
        grupoDisponible.miembros.push(condicion.usuarioId);
        await grupoDisponible.save();
      }
    }

    return res.status(201).json({
      condicion,
      grupoAsignado: grupoDisponible
        ? grupoDisponible.nombre
        : 'Sin grupo disponible para este nivel'
    });
  } catch (error) {
    console.error('❌ Error al guardar condición física:', error);

    return res.status(500).json({
      mensaje: 'Error al guardar la condición física',
      error: error.message
    });
  }
};

export const obtenerCondicionPorUsuario = async (req, res) => {
  try {
    const condiciones = await PhysicalCondition.find({
      usuarioId: req.params.usuarioId
    });

    return res.json(condiciones);
  } catch (error) {
    console.error('❌ Error al obtener condición física:', error);

    return res.status(500).json({
      mensaje: 'Error al obtener la condición física',
      error: error.message
    });
  }
};