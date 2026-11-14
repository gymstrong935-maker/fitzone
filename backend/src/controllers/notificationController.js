import Notification from '../models/Notification.js';

export const crearNotificacion = async (req, res) => {
  try {
    res.status(201).json(await Notification.create(req.body));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const obtenerNotificacionesPorUsuario = async (req, res) => {
  try {
    const notificaciones = await Notification
      .find({ usuarioId: req.params.usuarioId })
      .sort({ fechaEnvio: -1 })
      .limit(100);

    res.json(notificaciones);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const marcarComoLeida = async (req, res) => {
  try {
    const filtro = { _id: req.params.id };

    // Un usuario normal solo puede marcar sus propias notificaciones.
    if (req.usuario?.rol !== 'admin') {
      filtro.usuarioId = req.usuario.id;
    }

    const notificacion = await Notification.findOneAndUpdate(
      filtro,
      { leida: true },
      { new: true }
    );

    if (!notificacion) return res.status(404).json({ mensaje: 'Notificación no encontrada' });
    res.json(notificacion);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const marcarTodasComoLeidas = async (req, res) => {
  try {
    const resultado = await Notification.updateMany(
      { usuarioId: req.params.usuarioId, leida: false },
      { $set: { leida: true } }
    );
    res.json({ mensaje: 'Notificaciones marcadas como leídas', actualizadas: resultado.modifiedCount });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};