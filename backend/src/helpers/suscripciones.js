import Subscription from '../models/Subscription.js';
import Payment, { METODOS_PAGO } from '../models/Payment.js';
import notificarAdmin from './notificarAdmin.js';
import { escapeHtml } from '../utils/emailTemplates.js';

// Solo se aceptan los métodos vigentes; cualquier otro valor queda "Sin definir"
// hasta que el usuario elija en la pantalla de pago.
const normalizarMetodo = (metodo) => (METODOS_PAGO.includes(metodo) ? metodo : 'Sin definir');

const crearSuscripcionParaPlan = async (usuario, plan, metodoPago) => {
  await Subscription.updateMany(
    { usuarioId: usuario._id, estado: 'pendiente' },
    { $set: { estado: 'cancelada' } }
  );

  if (plan.esGratuito) {
    const fechaInicio = new Date();
    const fechaFin = new Date();
    fechaFin.setDate(fechaFin.getDate() + plan.duracionDias);

    return await Subscription.create({
      usuarioId: usuario._id,
      planId: plan._id,
      fechaInicio,
      fechaFin,
      estado: 'activa'
    });
  }

  const nuevaSuscripcion = await Subscription.create({
    usuarioId: usuario._id,
    planId: plan._id,
    fechaInicio: null,
    fechaFin: null,
    estado: 'pendiente'
  });

  const metodo = normalizarMetodo(metodoPago);

  await Payment.create({
    usuarioId: usuario._id,
    suscripcionId: nuevaSuscripcion._id,
    tipo: 'suscripcion',
    monto: plan.precio,
    metodoPago: metodo,
    estado: 'pendiente'
  });

  await notificarAdmin({
    mensaje: `${usuario.nombre} solicitó el plan "${plan.nombre}" ($${plan.precio}). Espera su pago y la aprobación.`,
    asuntoCorreo: 'FitZone - Nueva solicitud de plan pendiente',
    htmlCorreo: `<p>El usuario <strong>${escapeHtml(usuario.nombre)}</strong> (${escapeHtml(usuario.email)}) solicitó el plan <strong>${escapeHtml(plan.nombre)}</strong> por <strong>$${plan.precio}</strong>.</p>
                 <p>Cuando suba su comprobante (o elija efectivo) verifica el pago y aprueba o rechaza la solicitud desde el panel de administración.</p>`
  });

  return nuevaSuscripcion;
};

// ¿Qué plan "bloquea" el ingreso de este usuario?
// Es el de su suscripción vigente (activa y sin vencer) o el de la que está pendiente.
// Si no tiene ninguna (todo vencido / rechazado / cancelado) devuelve null:
// en ese caso sí puede entrar con otro plan.
const planBloqueante = async (usuarioId) => {
  const subs = await Subscription.find({ usuarioId }).sort({ _id: -1 });
  const ahora = new Date();

  const vigente = subs.find(
    (s) => s.estado === 'activa' && (!s.fechaFin || s.fechaFin > ahora)
  );
  if (vigente) return { planId: vigente.planId, estado: 'activa', fechaFin: vigente.fechaFin };

  const pendiente = subs.find((s) => s.estado === 'pendiente');
  if (pendiente) return { planId: pendiente.planId, estado: 'pendiente', fechaFin: null };

  return null;
};

export { crearSuscripcionParaPlan, planBloqueante, normalizarMetodo };
