import cron from 'node-cron';
import { ejecutarRevisionVencimientos } from '../helpers/vencimientos.js';

const ejecutarVerificacion = async () => {
  try {
    const r = await ejecutarRevisionVencimientos();
    console.log(
      `🕐 [Cron] Vencimientos: ${r.notificacionesEnviadas} avisos, ${r.suscripcionesVencidas} suscripciones vencidas`
    );
  } catch (error) {
    console.error('❌ [Cron] Error al verificar vencimientos:', error.message);
  }
};

// Corre todos los días a la 1:00 AM
export const iniciarJobVencimientos = () => {
  cron.schedule('0 1 * * *', ejecutarVerificacion);
  console.log('✅ Job de verificación de vencimientos programado (diario, 1:00 AM)');
};
