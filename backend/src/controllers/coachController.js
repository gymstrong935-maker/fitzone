import Coach from '../models/Coach.js';
import User from '../models/User.js';
import Plan from '../models/Plan.js';
import Appointment from '../models/Appointment.js';
import { borrarImagenCloudinary } from '../utils/cloudinary.js';
import { normalizarDisponibilidad } from '../utils/horarios.js';

// El admin puede indicar la foto como una URL pública (https://...)
const urlDeFoto = (valor) =>
  typeof valor === 'string' && /^https?:\/\/\S+$/i.test(valor.trim()) ? valor.trim() : undefined;

// Deja los horarios en el formato oficial ("lunes 06:00-12:00"). Si alguno no se
// entiende, devuelve el mensaje de error para responder 400 en vez de guardarlo roto.
const prepararDisponibilidad = (datos) => {
  if (datos.disponibilidad === undefined) return null;

  let lista = datos.disponibilidad;
  if (typeof lista === 'string') {
    try { lista = JSON.parse(lista); } catch { lista = lista.split(/[\n;]/); } // multipart: llega como texto
  }

  const { validos, invalidos } = normalizarDisponibilidad(lista);

  if (invalidos.length) {
    return `Estos horarios no se entienden: ${invalidos.join(' | ')}. Usa el formato "lunes 06:00-12:00" (cada rango debe durar al menos 1 hora).`;
  }

  datos.disponibilidad = validos;
  return null;
};

export const crearCoach = async (req, res) => {
  try {
    const datosCoach = { ...req.body };

    const errorHorarios = prepararDisponibilidad(datosCoach);
    if (errorHorarios) return res.status(400).json({ mensaje: errorHorarios });

    // Estos campos solo se asignan de forma controlada
    delete datosCoach.fotoPerfil;
    delete datosCoach.fotoPerfilId;
    delete datosCoach.clientesAsignados;

    const url = urlDeFoto(req.body.fotoPerfil);
    if (url) datosCoach.fotoPerfil = url;

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
  try {
    // La lista de clientes asignados es privada
    res.json(await Coach.find().select('-clientesAsignados'));
  }
  catch (e) { res.status(500).json({ error: e.message }); }
};

// Actualizar entrenador (foto por archivo o por URL)
export const actualizarCoach = async (req, res) => {
  try {
    const datosActualizar = { ...req.body };

    const errorHorarios = prepararDisponibilidad(datosActualizar);
    if (errorHorarios) return res.status(400).json({ mensaje: errorHorarios });

    delete datosActualizar.fotoPerfil;
    delete datosActualizar.fotoPerfilId;
    delete datosActualizar.clientesAsignados;

    const coachActual = await Coach.findById(req.params.id);
    if (!coachActual) return res.status(404).json({ mensaje: 'Entrenador no encontrado' });

    const url = urlDeFoto(req.body.fotoPerfil);

    if (req.file) {
      if (coachActual.fotoPerfilId) {
        await borrarImagenCloudinary(coachActual.fotoPerfilId);
      }
      datosActualizar.fotoPerfil = req.file.secure_url;
      datosActualizar.fotoPerfilId = req.file.public_id;
    } else if (url && url !== coachActual.fotoPerfil) {
      if (coachActual.fotoPerfilId) {
        await borrarImagenCloudinary(coachActual.fotoPerfilId);
      }
      datosActualizar.fotoPerfil = url;
      datosActualizar.fotoPerfilId = null;
    }

    const coach = await Coach
      .findByIdAndUpdate(req.params.id, datosActualizar, { new: true })
      .select('-clientesAsignados');
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

    // Limpieza: sus clientes quedan sin entrenador y se cancelan sus citas futuras
    await User.updateMany({ entrenadorAsignado: coach._id }, { $unset: { entrenadorAsignado: 1 } });
    await Appointment.updateMany(
      { entrenadorId: coach._id, estado: 'confirmada' },
      { $set: { estado: 'cancelada' } }
    );

    res.json({ mensaje: 'Entrenador eliminado' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// ======================================================
// ASIGNARME UN ENTRENADOR (el usuario del token)
// ======================================================

export const asignarmeEntrenador = async (req, res) => {
  try {
    const coach = await Coach.findById(req.params.id);
    if (!coach) return res.status(404).json({ mensaje: 'Entrenador no encontrado' });

    const usuario = await User.findById(req.usuario.id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    // Solo los planes de pago incluyen entrenador personal
    const plan = usuario.planActual ? await Plan.findById(usuario.planActual) : null;
    if (!plan || plan.esGratuito) {
      return res.status(403).json({ mensaje: 'Tu plan no incluye entrenador personal' });
    }

    const anterior = usuario.entrenadorAsignado;

    if (anterior && String(anterior) === String(coach._id)) {
      return res.json({ mensaje: 'Ya tienes asignado este entrenador', entrenadorAsignado: coach._id });
    }

    // Cambiar de entrenador requiere solicitud: la valida el admin y, si el nuevo
    // cuesta más, se paga la diferencia (POST /api/coaches/cambio).
    if (anterior) {
      const sigueExistiendo = await Coach.exists({ _id: anterior });

      if (sigueExistiendo) {
        return res.status(409).json({
          mensaje: 'Para cambiar de entrenador debes enviar una solicitud que valida el equipo.',
          codigo: 'USAR_CAMBIO'
        });
      }
    }

    usuario.entrenadorAsignado = coach._id;
    await usuario.save();

    await Coach.findByIdAndUpdate(coach._id, { $addToSet: { clientesAsignados: usuario._id } });

    res.json({ mensaje: 'Entrenador asignado', entrenadorAsignado: coach._id });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};