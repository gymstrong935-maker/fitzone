import mongoose from 'mongoose';
import Appointment from '../models/Appointment.js';
import Coach from '../models/Coach.js';
import User from '../models/User.js';
import Notification from '../models/Notification.js';

const avisar = async (usuarioId, mensaje) => {
  try {
    await Notification.create({ usuarioId, tipo: 'recordatorio', mensaje, leida: false });
  } catch (error) {
    console.error('❌ No se pudo crear la notificación:', error.message);
  }
};

export const crearCita = async (req, res) => {
  try {
    const { entrenadorId, usuarioId, fecha, hora } = req.body;

    if (!mongoose.isValidObjectId(entrenadorId)) {
      return res.status(400).json({ mensaje: 'Entrenador no válido' });
    }

    const coach = await Coach.findById(entrenadorId);
    if (!coach) {
      return res.status(404).json({ mensaje: 'Entrenador no encontrado' });
    }

    // Un usuario normal solo puede agendar con su entrenador asignado
    if (req.usuario?.rol !== 'admin') {
      const usuario = await User.findById(usuarioId).select('entrenadorAsignado');

      if (!usuario?.entrenadorAsignado || String(usuario.entrenadorAsignado) !== String(entrenadorId)) {
        return res.status(403).json({ mensaje: 'Solo puedes agendar citas con tu entrenador asignado' });
      }
    }

    const yaOcupado = await Appointment.findOne({
      entrenadorId, fecha, hora, estado: 'confirmada'
    });

    if (yaOcupado) {
      return res.status(409).json({ mensaje: 'Ese horario con este entrenador ya está reservado' });
    }

    const nuevaCita = await Appointment.create({ entrenadorId, usuarioId, fecha, hora });

    await avisar(usuarioId, `Tu cita con ${coach.nombre} quedó confirmada para el ${fecha} a las ${hora}.`);

    res.status(201).json(nuevaCita);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ mensaje: 'Ese horario con este entrenador ya está reservado' });
    }
    res.status(500).json({ error: error.message });
  }
};

// Horarios ocupados de un entrenador (solo fecha y hora, sin datos de usuarios)
export const obtenerCitasPorEntrenador = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.entrenadorId)) {
      return res.status(400).json({ mensaje: 'Entrenador no válido' });
    }

    const citas = await Appointment
      .find({ entrenadorId: req.params.entrenadorId, estado: 'confirmada' })
      .select('entrenadorId fecha hora estado');

    res.json(citas);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const obtenerCitasPorUsuario = async (req, res) => {
  try {
    const citas = await Appointment
      .find({ usuarioId: req.params.usuarioId })
      .populate('entrenadorId', 'nombre fotoPerfil')
      .sort({ fecha: 1, hora: 1 });

    res.json(citas);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const cancelarCita = async (req, res) => {
  try {
    const filtro = { _id: req.params.id };

    // Un usuario normal solo puede cancelar sus propias citas
    if (req.usuario?.rol !== 'admin') {
      filtro.usuarioId = req.usuario.id;
    }

    const cita = await Appointment
      .findOneAndUpdate(filtro, { estado: 'cancelada' }, { new: true })
      .populate('entrenadorId', 'nombre');

    if (!cita) return res.status(404).json({ mensaje: 'Cita no encontrada' });

    await avisar(
      cita.usuarioId,
      `Cancelaste tu cita con ${cita.entrenadorId?.nombre || 'tu entrenador'} del ${cita.fecha} a las ${cita.hora}.`
    );

    res.json(cita);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};