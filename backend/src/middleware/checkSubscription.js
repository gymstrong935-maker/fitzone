import Subscription from '../models/Subscription.js';

const checkSubscription = async (req, res, next) => {
  try {
    const usuarioId = req.usuario?.id;
    if (!usuarioId) return res.status(401).json({ mensaje: 'Token no proporcionado' });

    const suscripcionActiva = await Subscription.findOne({
      usuarioId,
      estado: 'activa',
      fechaFin: { $gte: new Date() }
    });

    if (!suscripcionActiva) {
      return res.status(403).json({
        mensaje: 'No tienes una suscripción activa. Verifica el estado de tu plan o espera la aprobación del administrador.'
      });
    }

    req.suscripcion = suscripcionActiva; // disponible por si el controller la necesita
    next();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export default checkSubscription;