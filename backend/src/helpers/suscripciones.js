import Subscription from '../models/Subscription.js';
import notificarAdmin from './notificarAdmin.js';

// Crea una suscripción nueva para un usuario, según si el plan es gratuito o pago
const crearSuscripcionParaPlan = async (usuario, plan) => {
  // Si el plan es gratuito, verifica que el usuario no lo haya usado ya antes
  if (plan.esGratuito) {
    const yaUsoGratis = await Subscription.findOne({ usuarioId: usuario._id, planId: plan._id });
    if (yaUsoGratis) {
      throw new Error('PLAN_GRATUITO_YA_USADO');
    }
  }

  // Cancela cualquier solicitud pendiente anterior del mismo usuario antes de crear una nueva
  await Subscription.updateMany(
    { usuarioId: usuario._id, estado: 'pendiente' },
    { $set: { estado: 'cancelada' } }
  );

  if (plan.esGratuito) {
    // Plan gratuito: se activa de inmediato
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
  } else {
    // Plan pago: queda pendiente de aprobación por el admin
    const nuevaSuscripcion = await Subscription.create({
      usuarioId: usuario._id,
      planId: plan._id,
      fechaInicio: null,
      fechaFin: null,
      estado: 'pendiente'
    });

    await notificarAdmin({
      mensaje: `${usuario.nombre} solicitó el plan "${plan.nombre}" y espera aprobación de pago.`,
      asuntoCorreo: 'FitZone - Nueva solicitud de plan pendiente',
      htmlCorreo: `<p>El usuario <strong>${usuario.nombre}</strong> (${usuario.email}) solicitó el plan <strong>${plan.nombre}</strong>.</p>
                   <p>Verifica el pago y aprueba o rechaza la solicitud desde el panel de administración.</p>`
    });

    return nuevaSuscripcion;
  }
};

export { crearSuscripcionParaPlan };