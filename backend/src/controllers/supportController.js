import mongoose from 'mongoose';
import SupportTicket from '../models/SupportTicket.js';

const MAX_ABIERTOS = 5;

export const crearTicket = async (req, res) => {
  try {
    const { usuarioId, asunto, mensaje, transcripcion } = req.body;

    const abiertos = await SupportTicket.countDocuments({ usuarioId, estado: { $ne: 'cerrado' } });
    if (abiertos >= MAX_ABIERTOS) {
      return res.status(429).json({
        mensaje: `Ya tienes ${MAX_ABIERTOS} solicitudes abiertas. Espera a que las atendamos antes de crear otra.`
      });
    }

    const ticket = await SupportTicket.create({ usuarioId, asunto, mensaje, transcripcion });
    res.status(201).json(ticket);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const misTickets = async (req, res) => {
  try {
    const tickets = await SupportTicket
      .find({ usuarioId: req.usuario.id })
      .sort({ updatedAt: -1 })
      .limit(50);

    res.json(tickets);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// El usuario agrega un mensaje a una de sus solicitudes
export const agregarMensaje = async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Solicitud no válida' });
    }

    const ticket = await SupportTicket.findOne({ _id: req.params.id, usuarioId: req.usuario.id });
    if (!ticket) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });

    ticket.respuestas.push({ autor: 'usuario', mensaje: req.body.mensaje });
    if (ticket.estado === 'cerrado') ticket.estado = 'abierto';
    await ticket.save();

    res.json(ticket);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};