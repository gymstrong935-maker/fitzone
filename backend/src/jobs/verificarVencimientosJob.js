import cron from 'node-cron';
import Subscription from '../models/Subscription.js';
import Notification from '../models/Notification.js';

const ejecutarVerificacion = async () => {
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

    console.log(`🕐 [Cron] Verificación de vencimientos: ${notificacionesCreadas} notificaciones, ${vencidas.modifiedCount} suscripciones vencidas`);
  } catch (error) {
    console.error('❌ [Cron] Error al verificar vencimientos:', error.message);
  }
};

// Corre todos los días a la 1:00 AM
export const iniciarJobVencimientos = () => {
  cron.schedule('0 1 * * *', ejecutarVerificacion);
  console.log('✅ Job de verificación de vencimientos programado (diario, 1:00 AM)');
};