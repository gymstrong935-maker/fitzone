import Appointment from '../models/Appointment.js';

export const crearCita = async (req, res) => {
  try {
    const { entrenadorId, usuarioId, fecha, hora } = req.body;

    const yaOcupado = await Appointment.findOne({
      entrenadorId, fecha, hora, estado: 'confirmada'
    });

    if (yaOcupado) {
      return res.status(409).json({ mensaje: 'Ese horario con este entrenador ya está reservado' });
    }

    const nuevaCita = await Appointment.create({ entrenadorId, usuarioId, fecha, hora });
    res.status(201).json(nuevaCita);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ mensaje: 'Ese horario con este entrenador ya está reservado' });
    }
    res.status(500).json({ error: error.message });
  }
};

export const obtenerCitasPorEntrenador = async (req, res) => {
  try {
    const citas = await Appointment.find({ entrenadorId: req.params.entrenadorId, estado: 'confirmada' });
    res.json(citas);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const obtenerCitasPorUsuario = async (req, res) => {
  try {
    const citas = await Appointment.find({ usuarioId: req.params.usuarioId });
    res.json(citas);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const cancelarCita = async (req, res) => {
  try {
    const cita = await Appointment.findByIdAndUpdate(req.params.id, { estado: 'cancelada' }, { new: true });
    if (!cita) return res.status(404).json({ mensaje: 'Cita no encontrada' });
    res.json(cita);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};