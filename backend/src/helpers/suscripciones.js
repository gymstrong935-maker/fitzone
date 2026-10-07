import Subscription from '../models/Subscription.js';
import Payment from '../models/Payment.js';
import notificarAdmin from './notificarAdmin.js';

const crearSuscripcionParaPlan = async (usuario, plan, metodoPago = 'Transferencia bancaria') => {
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
  } else {
    const nuevaSuscripcion = await Subscription.create({
      usuarioId: usuario._id,
      planId: plan._id,
      fechaInicio: null,
      fechaFin: null,
      estado: 'pendiente'
    });

    await Payment.create({
      usuarioId: usuario._id,
      suscripcionId: nuevaSuscripcion._id,
      monto: plan.precio,
      metodoPago,
      estado: 'pendiente'
    });

    await notificarAdmin({
      mensaje: `${usuario.nombre} solicitó el plan "${plan.nombre}" (${plan.precio}) vía ${metodoPago} y espera aprobación de pago.`,
      asuntoCorreo: 'FitZone - Nueva solicitud de plan pendiente',
      htmlCorreo: `<p>El usuario <strong>${usuario.nombre}</strong> (${usuario.email}) solicitó el plan <strong>${plan.nombre}</strong> por <strong>$${plan.precio}</strong>, pagando por <strong>${metodoPago}</strong>.</p>
                   <p>Verifica el pago y aprueba o rechaza la solicitud desde el panel de administración.</p>`
    });

    return nuevaSuscripcion;
  }
};

export { crearSuscripcionParaPlan };