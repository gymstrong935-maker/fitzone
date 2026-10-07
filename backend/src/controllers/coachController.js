import Coach from '../models/Coach.js';
import { borrarImagenCloudinary } from '../utils/cloudinary.js';

export const crearCoach = async (req, res) => {
  try {
    const datosCoach = { ...req.body };

    // Nunca permitir que el cliente asigne estos campos directamente
    delete datosCoach.fotoPerfil;
    delete datosCoach.fotoPerfilId;

    if (req.file) {
      datosCoach.fotoPerfil = req.file.secure_url;
      datosCoach.fotoPerfilId = req.file.public_id;
    }

    res.status(201).json(await Coach.create(datosCoach));
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ mensaje: 'Ya existe un entrenador con ese nombre' });
    res.status(500).json({ error: e.message });
  }
};

export const obtenerCoaches = async (req, res) => {
  try { res.json(await Coach.find()); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

// Actualizar entrenador (con foto de perfil opcional)
export const actualizarCoach = async (req, res) => {
  try {
    const datosActualizar = { ...req.body };

    delete datosActualizar.fotoPerfil;
    delete datosActualizar.fotoPerfilId;

    const coachActual = await Coach.findById(req.params.id);
    if (!coachActual) return res.status(404).json({ mensaje: 'Entrenador no encontrado' });

    if (req.file) {
      if (coachActual.fotoPerfilId) {
        await borrarImagenCloudinary(coachActual.fotoPerfilId);
      }
      datosActualizar.fotoPerfil = req.file.secure_url;
      datosActualizar.fotoPerfilId = req.file.public_id;
    }

    const coach = await Coach.findByIdAndUpdate(req.params.id, datosActualizar, { new: true });
    res.json(coach);
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ mensaje: 'Ya existe un entrenador con ese nombre' });
    res.status(500).json({ error: e.message });
  }
};

export const eliminarCoach = async (req, res) => {
  try {
    const coach = await Coach.findByIdAndDelete(req.params.id);
    if (!coach) return res.status(404).json({ mensaje: 'Entrenador no encontrado' });

    if (coach.fotoPerfilId) {
      await borrarImagenCloudinary(coach.fotoPerfilId);
    }

    res.json({ mensaje: 'Entrenador eliminado' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};