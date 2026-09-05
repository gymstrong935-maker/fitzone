import Notification from '../models/Notification.js';

export const obtenerNotificacionesPorUsuario = async (req, res) => {
  try {
    res.json(await Notification.find({ usuarioId: req.params.usuarioId }).sort({ fechaEnvio: -1 }));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const marcarComoLeida = async (req, res) => {
  try {
    const notif = await Notification.findById(req.params.id);
    if (!notif) return res.status(404).json({ mensaje: 'Notificación no encontrada' });

    if (notif.usuarioId.toString() !== req.usuario.id && req.usuario.rol !== 'admin') {
      return res.status(403).json({ mensaje: 'No autorizado' });
    }

    notif.leida = true;
    await notif.save();
    res.json(notif);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};