import Payment, { METODOS_PAGO } from '../models/Payment.js';
import CoachChangeRequest from '../models/CoachChangeRequest.js';
import User from '../models/User.js';
import notificarAdmin from '../helpers/notificarAdmin.js';
import { borrarImagenCloudinary } from '../utils/cloudinary.js';
import { escapeHtml } from '../utils/emailTemplates.js';

export const crearPago = async (req, res) => {
  try { res.status(201).json(await Payment.create(req.body)); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

export const obtenerPagosPorUsuario = async (req, res) => {
  try { res.json(await Payment.find({ usuarioId: req.params.usuarioId })); }
  catch (e) { res.status(500).json({ error: e.message }); }
};

// Pagos del usuario del token (más recientes primero)
export const obtenerMisPagos = async (req, res) => {
  try {
    const filtro = { usuarioId: req.usuario.id };
    if (req.query.estado) filtro.estado = req.query.estado;

    res.json(await Payment.find(filtro).sort({ _id: -1 }).limit(50));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// ======================================================
// El usuario elige cómo paga y (si es pago digital) sube la factura
// PUT /api/payments/:id/comprobante   (multipart: metodoPago + comprobante)
// ======================================================

export const registrarComprobante = async (req, res) => {
  try {
    const pago = await Payment.findById(req.params.id);

    if (!pago) {
      return res.status(404).json({ mensaje: 'Pago no encontrado' });
    }

    if (String(pago.usuarioId) !== String(req.usuario.id)) {
      return res.status(403).json({ mensaje: 'Este pago no es tuyo' });
    }

    if (pago.estado !== 'pendiente') {
      return res.status(400).json({
        mensaje: `Este pago ya fue ${pago.estado}. No se puede modificar.`
      });
    }

    const metodo = String(req.body.metodoPago || '').trim();

    if (!METODOS_PAGO.includes(metodo)) {
      return res.status(400).json({
        mensaje: 'Elige un método de pago válido: Efectivo o Pago digital.'
      });
    }

    if (metodo === 'Pago digital' && !req.file && !pago.comprobanteUrl) {
      return res.status(400).json({
        mensaje: 'Para el pago digital debes subir la imagen de la factura o comprobante.'
      });
    }

    if (req.file) {
      if (pago.comprobanteId) await borrarImagenCloudinary(pago.comprobanteId);

      pago.comprobanteUrl = req.file.secure_url || req.file.path;
      pago.comprobanteId = req.file.public_id || req.file.filename;
      pago.fechaComprobante = new Date();
    }

    pago.metodoPago = metodo;

    const referencia = String(req.body.referencia || '').trim();
    if (referencia) pago.referenciaTransaccion = referencia.slice(0, 60);

    await pago.save();

    // Si era la diferencia de un cambio de entrenador, la solicitud ya puede revisarse
    let detalle = 'tu suscripción';

    if (pago.tipo === 'cambio_entrenador' && pago.solicitudCambioId) {
      await CoachChangeRequest.updateOne(
        { _id: pago.solicitudCambioId, estado: 'pendiente_pago' },
        { $set: { estado: 'pendiente' } }
      );
      detalle = 'un cambio de entrenador';
    }

    const usuario = await User.findById(pago.usuarioId).select('nombre email');
    const monto = Number(pago.monto || 0).toLocaleString('es-CO');

    await notificarAdmin({
      mensaje:
        `${usuario?.nombre || 'Un usuario'} registró un pago (${metodo}) por $${monto} ` +
        `de ${detalle}. Falta validarlo.`,
      asuntoCorreo: 'FitZone - Pago por validar',
      htmlCorreo:
        `<p><strong>${escapeHtml(usuario?.nombre)}</strong> (${escapeHtml(usuario?.email)}) ` +
        `registró un pago por <strong>$${monto}</strong> mediante <strong>${escapeHtml(metodo)}</strong> ` +
        `correspondiente a ${detalle}.</p>` +
        (pago.comprobanteUrl
          ? `<p>Adjuntó la factura: <a href="${escapeHtml(pago.comprobanteUrl)}">ver comprobante</a>.</p>`
          : '<p>Pagará en efectivo de forma presencial.</p>') +
        '<p>Revísalo en el panel administrativo, sección <strong>Pagos</strong>.</p>'
    });

    res.json({ mensaje: 'Pago registrado. El equipo lo validará pronto.', pago });
  } catch (e) {
    console.error('❌ Error al registrar comprobante:', e);
    res.status(500).json({ mensaje: 'No se pudo registrar el pago. Inténtalo de nuevo.' });
  }
};
