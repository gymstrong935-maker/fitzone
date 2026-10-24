import mongoose from 'mongoose';
import Coach from '../models/Coach.js';
import User from '../models/User.js';
import Plan from '../models/Plan.js';
import Payment from '../models/Payment.js';
import Appointment from '../models/Appointment.js';
import CoachChangeRequest from '../models/CoachChangeRequest.js';
import notificarAdmin from '../helpers/notificarAdmin.js';
import notificarUsuario from '../helpers/notificarUsuario.js';
import { escapeHtml } from '../utils/emailTemplates.js';

const ABIERTAS = ['pendiente_pago', 'pendiente'];
const plata = (n) => `$${Number(n || 0).toLocaleString('es-CO')}`;

const poblar = (consulta) =>
  consulta
    .populate('entrenadorActualId', 'nombre fotoPerfil precio nivel')
    .populate('entrenadorNuevoId', 'nombre fotoPerfil precio nivel')
    .populate('usuarioId', 'nombre email')
    .populate('pagoId');

// ======================================================
// USUARIO: pedir el cambio
// POST /api/coaches/cambio   { entrenadorId }
// ======================================================

export const solicitarCambioEntrenador = async (req, res) => {
  try {
    const { entrenadorId } = req.body || {};

    if (!mongoose.isValidObjectId(entrenadorId)) {
      return res.status(400).json({ mensaje: 'Entrenador no válido' });
    }

    const usuario = await User.findById(req.usuario.id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    const plan = usuario.planActual ? await Plan.findById(usuario.planActual) : null;
    if (!plan || plan.esGratuito) {
      return res.status(403).json({ mensaje: 'Tu plan no incluye entrenador personal' });
    }

    const nuevo = await Coach.findById(entrenadorId);
    if (!nuevo) return res.status(404).json({ mensaje: 'Entrenador no encontrado' });

    if (!usuario.entrenadorAsignado) {
      return res.status(400).json({
        mensaje: 'Aún no tienes entrenador. Elígelo directamente, sin solicitud.',
        codigo: 'SIN_ENTRENADOR'
      });
    }

    if (String(usuario.entrenadorAsignado) === String(nuevo._id)) {
      return res.status(400).json({ mensaje: 'Ese ya es tu entrenador actual' });
    }

    const abierta = await CoachChangeRequest.findOne({
      usuarioId: usuario._id,
      estado: { $in: ABIERTAS }
    });

    if (abierta) {
      return res.status(409).json({
        mensaje: 'Ya tienes una solicitud de cambio en curso. Cancélala o espera la respuesta del equipo.',
        codigo: 'SOLICITUD_EN_CURSO'
      });
    }

    const actual = await Coach.findById(usuario.entrenadorAsignado);

    const precioActual = Number(actual?.precio || 0);
    const precioNuevo = Number(nuevo.precio || 0);
    const diferencia = Math.max(0, precioNuevo - precioActual);

    const solicitud = await CoachChangeRequest.create({
      usuarioId: usuario._id,
      entrenadorActualId: actual?._id,
      entrenadorNuevoId: nuevo._id,
      precioActual,
      precioNuevo,
      diferencia,
      estado: diferencia > 0 ? 'pendiente_pago' : 'pendiente'
    });

    if (diferencia > 0) {
      const pago = await Payment.create({
        usuarioId: usuario._id,
        tipo: 'cambio_entrenador',
        solicitudCambioId: solicitud._id,
        monto: diferencia,
        metodoPago: 'Sin definir',
        estado: 'pendiente'
      });

      solicitud.pagoId = pago._id;
      await solicitud.save();
    } else {
      await notificarAdmin({
        mensaje: `${usuario.nombre} pidió cambiar de entrenador (${actual?.nombre || '—'} → ${nuevo.nombre}). Sin costo adicional.`,
        asuntoCorreo: 'FitZone - Cambio de entrenador por validar',
        htmlCorreo:
          `<p><strong>${escapeHtml(usuario.nombre)}</strong> quiere cambiar de ` +
          `<strong>${escapeHtml(actual?.nombre || '—')}</strong> a <strong>${escapeHtml(nuevo.nombre)}</strong>. ` +
          'No tiene costo adicional.</p><p>Valídalo en el panel, sección <strong>Cambios de entrenador</strong>.</p>'
      });
    }

    res.status(201).json(await poblar(CoachChangeRequest.findById(solicitud._id)));
  } catch (e) {
    console.error('❌ Error al solicitar cambio de entrenador:', e);
    res.status(500).json({ mensaje: 'No se pudo crear la solicitud de cambio' });
  }
};

// Última solicitud del usuario (abierta o ya resuelta)
export const miSolicitudCambio = async (req, res) => {
  try {
    const solicitud = await poblar(
      CoachChangeRequest.findOne({ usuarioId: req.usuario.id }).sort({ _id: -1 })
    );
    res.json(solicitud || null);
  } catch (e) {
    res.status(500).json({ mensaje: e.message });
  }
};

export const cancelarSolicitudCambio = async (req, res) => {
  try {
    const solicitud = await CoachChangeRequest.findById(req.params.id);

    if (!solicitud || String(solicitud.usuarioId) !== String(req.usuario.id)) {
      return res.status(404).json({ mensaje: 'Solicitud no encontrada' });
    }

    if (!ABIERTAS.includes(solicitud.estado)) {
      return res.status(400).json({ mensaje: `La solicitud ya está ${solicitud.estado}` });
    }

    solicitud.estado = 'cancelada';
    solicitud.fechaResolucion = new Date();
    await solicitud.save();

    if (solicitud.pagoId) {
      await Payment.updateOne(
        { _id: solicitud.pagoId, estado: 'pendiente' },
        { $set: { estado: 'rechazado', notaAdmin: 'Cancelado por el usuario' } }
      );
    }

    res.json({ mensaje: 'Solicitud cancelada' });
  } catch (e) {
    res.status(500).json({ mensaje: e.message });
  }
};

// ======================================================
// ADMIN
// ======================================================

export const listarCambiosEntrenador = async (req, res) => {
  try {
    const filtro = {};
    if (req.query.estado) filtro.estado = req.query.estado;

    const lista = await poblar(CoachChangeRequest.find(filtro).sort({ _id: -1 }).limit(200));
    res.json(lista);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export const aprobarCambioEntrenador = async (req, res) => {
  try {
    const solicitud = await CoachChangeRequest.findById(req.params.id);
    if (!solicitud) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });

    if (solicitud.estado === 'pendiente_pago') {
      return res.status(400).json({
        mensaje: 'El usuario aún no ha registrado el pago de la diferencia.'
      });
    }

    if (solicitud.estado !== 'pendiente') {
      return res.status(400).json({ mensaje: `La solicitud ya está ${solicitud.estado}` });
    }

    const pago = solicitud.pagoId ? await Payment.findById(solicitud.pagoId) : null;

    if (pago && pago.estado === 'pendiente') {
      if (pago.metodoPago === 'Sin definir') {
        return res.status(400).json({ mensaje: 'El usuario no ha elegido cómo pagar.' });
      }
      if (pago.metodoPago === 'Pago digital' && !pago.comprobanteUrl) {
        return res.status(400).json({ mensaje: 'Falta la factura del pago digital.' });
      }
    }

    const usuario = await User.findById(solicitud.usuarioId);
    const nuevo = await Coach.findById(solicitud.entrenadorNuevoId);

    if (!usuario || !nuevo) {
      return res.status(400).json({
        mensaje: 'El usuario o el entrenador ya no existen. Rechaza la solicitud.'
      });
    }

    const anterior = usuario.entrenadorAsignado;

    if (anterior) {
      await Coach.findByIdAndUpdate(anterior, { $pull: { clientesAsignados: usuario._id } });

      // Sus citas futuras con el entrenador anterior ya no aplican
      const hoy = new Date().toISOString().slice(0, 10);
      await Appointment.updateMany(
        { usuarioId: usuario._id, entrenadorId: anterior, estado: 'confirmada', fecha: { $gte: hoy } },
        { $set: { estado: 'cancelada' } }
      );
    }

    usuario.entrenadorAsignado = nuevo._id;
    await usuario.save();
    await Coach.findByIdAndUpdate(nuevo._id, { $addToSet: { clientesAsignados: usuario._id } });

    if (pago && pago.estado === 'pendiente') {
      pago.estado = 'aprobado';
      await pago.save();
    }

    solicitud.estado = 'aprobada';
    solicitud.fechaResolucion = new Date();
    await solicitud.save();

    await notificarUsuario(usuario, {
      mensaje: `Tu cambio de entrenador fue aprobado. Ahora entrenas con ${nuevo.nombre}.`,
      asuntoCorreo: 'FitZone - Cambio de entrenador aprobado',
      htmlCorreo: `<p>Hola ${escapeHtml(usuario.nombre)},</p><p>Tu cambio fue aprobado: tu nuevo entrenador es <strong>${escapeHtml(nuevo.nombre)}</strong>.</p>`
    });

    res.json({ mensaje: 'Cambio aprobado', solicitud });
  } catch (e) {
    console.error('❌ Error al aprobar cambio de entrenador:', e);
    res.status(500).json({ error: e.message });
  }
};

export const rechazarCambioEntrenador = async (req, res) => {
  try {
    const solicitud = await CoachChangeRequest.findById(req.params.id);
    if (!solicitud) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });

    if (!ABIERTAS.includes(solicitud.estado)) {
      return res.status(400).json({ mensaje: `La solicitud ya está ${solicitud.estado}` });
    }

    const motivo = String(req.body?.motivo || '').trim().slice(0, 200);

    solicitud.estado = 'rechazada';
    solicitud.motivoRechazo = motivo || undefined;
    solicitud.fechaResolucion = new Date();
    await solicitud.save();

    if (solicitud.pagoId) {
      await Payment.updateOne(
        { _id: solicitud.pagoId, estado: 'pendiente' },
        { $set: { estado: 'rechazado', notaAdmin: motivo || 'Cambio rechazado' } }
      );
    }

    const usuario = await User.findById(solicitud.usuarioId);

    if (usuario) {
      await notificarUsuario(usuario, {
        mensaje: `Tu solicitud de cambio de entrenador fue rechazada.${motivo ? ' Motivo: ' + motivo : ''}`,
        asuntoCorreo: 'FitZone - Cambio de entrenador rechazado',
        htmlCorreo: `<p>Hola ${escapeHtml(usuario.nombre)},</p><p>Tu solicitud de cambio de entrenador fue rechazada.</p>${motivo ? `<p>Motivo: ${escapeHtml(motivo)}</p>` : ''}`
      });
    }

    res.json({ mensaje: 'Cambio rechazado', solicitud });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

export { plata };
