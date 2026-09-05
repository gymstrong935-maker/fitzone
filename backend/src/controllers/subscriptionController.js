import Subscription from '../models/Subscription.js';
import Plan from '../models/Plan.js';
import User from '../models/User.js';
import Notification from '../models/Notification.js';
import { crearSuscripcionParaPlan } from '../helpers/suscripciones.js';
import notificarUsuario from '../helpers/notificarUsuario.js';

export const obtenerSuscripcionPorUsuario = async (req, res) => {
  try { res.json(await Subscription.find({ usuarioId: req.params.usuarioId })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const verificarVencimientos = async (req, res) => {
  try {
    const ahora = new Date();
    const enUnDia = new Date();
    enUnDia.setDate(enUnDia.getDate() + 1);

    const porVencer = await Subscription.find({
      estado: 'activa',
      fechaFin: { $gte: ahora, $lte: enUnDia }
    });

    let notificacionesCreadas = 0;

    for (const sub of porVencer) {
      const yaNotificado = await Notification.findOne({
        usuarioId: sub.usuarioId,
        tipo: 'recordatorio',
        leida: false
      });

      if (!yaNotificado) {
        await Notification.create({
          usuarioId: sub.usuarioId,
          tipo: 'recordatorio',
          mensaje: 'Tu plan vence en menos de 24 horas. Renueva para no perder acceso.',
          leida: false
        });
        notificacionesCreadas++;
      }
    }

    const vencidas = await Subscription.updateMany(
      { estado: 'activa', fechaFin: { $lt: ahora } },
      { $set: { estado: 'vencida' } }
    );

    res.json({
      mensaje: 'Verificación completada',
      notificacionesEnviadas: notificacionesCreadas,
      suscripcionesVencidas: vencidas.modifiedCount
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Solicita un cambio de plan (gratuito se activa directo, pago queda pendiente de aprobación)
export const cambiarPlan = async (req, res) => {
  try {
    const { usuarioId, nuevoPlanId } = req.body;

    const usuario = await User.findById(usuarioId);
    const plan = await Plan.findById(nuevoPlanId);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });

    const nuevaSuscripcion = await crearSuscripcionParaPlan(usuario, plan);

    res.json({
      mensaje: nuevaSuscripcion.estado === 'activa'
        ? 'Plan gratuito activado'
        : 'Solicitud de cambio de plan enviada, pendiente de aprobación',
      suscripcion: nuevaSuscripcion
    });
  } catch (error) {
    if (error.message === 'PLAN_GRATUITO_YA_USADO') {
      return res.status(400).json({ mensaje: 'Ya usaste tu plan gratuito de prueba' });
    }
    res.status(500).json({ error: error.message });
  }
};

// Lista las solicitudes de plan pago pendientes de revisión (admin)
export const obtenerPendientes = async (req, res) => {
  try {
    const pendientes = await Subscription.find({ estado: 'pendiente' })
      .populate('usuarioId', 'nombre email telefono cuentaVerificada')
      .populate('planId', 'nombre precio duracionDias')
      .sort({ createdAt: 1 });

    res.json(pendientes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Aprueba una solicitud de plan pago (admin)
export const aprobarSuscripcion = async (req, res) => {
  try {
    const suscripcion = await Subscription.findById(req.params.id).populate('planId').populate('usuarioId');
    if (!suscripcion) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });
    if (suscripcion.estado !== 'pendiente') {
      return res.status(400).json({ mensaje: `Esta solicitud ya fue ${suscripcion.estado}` });
    }

    if (!suscripcion.usuarioId.cuentaVerificada) {
      return res.status(400).json({
        mensaje: 'No se puede aprobar: el usuario aún no ha verificado su cuenta'
      });
    }

    await Subscription.updateMany(
      { usuarioId: suscripcion.usuarioId._id, estado: 'activa', _id: { $ne: suscripcion._id } },
      { $set: { estado: 'cancelada' } }
    );

    const fechaInicio = new Date();
    const fechaFin = new Date(fechaInicio);
    fechaFin.setDate(fechaFin.getDate() + suscripcion.planId.duracionDias);

    suscripcion.estado = 'activa';
    suscripcion.fechaInicio = fechaInicio;
    suscripcion.fechaFin = fechaFin;
    await suscripcion.save();

    await User.findByIdAndUpdate(suscripcion.usuarioId._id, { planActual: suscripcion.planId._id });

    await notificarUsuario(suscripcion.usuarioId, {
      mensaje: `Tu plan "${suscripcion.planId.nombre}" fue aprobado y ya está activo.`,
      asuntoCorreo: 'FitZone - Tu plan fue aprobado',
      htmlCorreo: `<p>Hola ${suscripcion.usuarioId.nombre},</p>
                   <p>Tu solicitud del plan <strong>${suscripcion.planId.nombre}</strong> fue aprobada.</p>
                   <p>Vigencia: ${fechaInicio.toLocaleDateString()} - ${fechaFin.toLocaleDateString()}</p>`
    });

    res.json({ mensaje: 'Suscripción aprobada', suscripcion });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Rechaza una solicitud de plan pago (admin)
export const rechazarSuscripcion = async (req, res) => {
  try {
    const suscripcion = await Subscription.findById(req.params.id).populate('planId').populate('usuarioId');
    if (!suscripcion) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });
    if (suscripcion.estado !== 'pendiente') {
      return res.status(400).json({ mensaje: `Esta solicitud ya fue ${suscripcion.estado}` });
    }

    suscripcion.estado = 'rechazada';
    await suscripcion.save();

    const motivo = req.body.motivo;

    await notificarUsuario(suscripcion.usuarioId, {
      mensaje: `Tu solicitud del plan "${suscripcion.planId.nombre}" fue rechazada.${motivo ? ' Motivo: ' + motivo : ''}`,
      asuntoCorreo: 'FitZone - Tu solicitud de plan fue rechazada',
      htmlCorreo: `<p>Hola ${suscripcion.usuarioId.nombre},</p>
                   <p>Tu solicitud del plan <strong>${suscripcion.planId.nombre}</strong> fue rechazada.</p>
                   ${motivo ? `<p>Motivo: ${motivo}</p>` : ''}
                   <p>Si crees que es un error, contáctanos.</p>`
    });

    res.json({ mensaje: 'Suscripción rechazada', suscripcion });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Devuelve el estado del plan del usuario autenticado (para pantallas tipo "mi plan")
export const obtenerMiSuscripcion = async (req, res) => {
  try {
    const suscripcion = await Subscription.findOne({ usuarioId: req.usuario.id, estado: 'activa' })
      .populate('planId', 'nombre precio duracionDias beneficios esGratuito')
      .sort({ fechaFin: -1 });

    if (!suscripcion) {
      return res.json({
        tieneSuscripcionActiva: false,
        mensaje: 'No tienes un plan activo'
      });
    }

    const ahora = new Date();
    const msRestantes = suscripcion.fechaFin - ahora;
    const diasRestantes = Math.max(0, Math.ceil(msRestantes / (1000 * 60 * 60 * 24)));

    res.json({
      tieneSuscripcionActiva: true,
      plan: suscripcion.planId,
      estado: suscripcion.estado,
      fechaInicio: suscripcion.fechaInicio,
      fechaFin: suscripcion.fechaFin,
      diasRestantes
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Limpieza de suscripciones canceladas de un usuario (solo mantenimiento, admin)
export const limpiarCanceladas = async (req, res) => {
  try {
    const resultado = await Subscription.deleteMany({
      usuarioId: req.params.usuarioId,
      estado: 'cancelada'
    });
    res.json({
      mensaje: 'Limpieza completada',
      eliminadas: resultado.deletedCount
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};