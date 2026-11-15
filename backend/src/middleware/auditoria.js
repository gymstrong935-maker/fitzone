import mongoose from 'mongoose';
import User from '../models/User.js';
import { registrarActividad, camposDe, etiquetaCampos } from '../utils/actividad.js';

// ======================================================
// HISTORIAL DE CAMBIOS
//
// Registra de forma automática las acciones que cambian datos (POST/PUT/PATCH/DELETE)
// cuando salen bien. Cada regla dice cómo se llama la acción y cómo se muestra.
//   m  = grupos de la ruta   ·   c = campos enviados   ·   o = nombre del objetivo (acciones del admin)
// ======================================================

const ID = '[a-fA-F0-9]{24}';

const REGLAS = [
  // --- Cuenta y perfil ---
  ['PUT', `^/api/users/(${ID})/password$`, 'cuenta', 'cambio_password', () => 'Cambió su contraseña'],
  ['POST', `^/api/users/(${ID})/cambio-correo$`, 'cuenta', 'solicitud_cambio_correo', () => 'Pidió cambiar su correo'],
  ['POST', `^/api/users/(${ID})/cambio-correo/confirmar$`, 'cuenta', 'cambio_correo', () => 'Confirmó su nuevo correo'],
  ['PUT', `^/api/users/(${ID})$`, 'perfil', 'perfil_actualizado',
    ({ c, foto }) => {
      const partes = [];
      if (c.length) partes.push(`datos (${etiquetaCampos(c)})`);
      if (foto) partes.push('foto de perfil');
      return `Actualizó su perfil${partes.length ? ': ' + partes.join(' y ') : ''}`;
    }],

  // --- Salud y onboarding ---
  ['POST', '^/api/physical-measurements$', 'salud', 'medidas', () => 'Registró sus medidas corporales'],
  ['POST', '^/api/physical-conditions$', 'salud', 'condicion_fisica', () => 'Actualizó su condición física'],
  ['POST', '^/api/sleep-quality$', 'salud', 'sueno', () => 'Registró su calidad de sueño'],
  ['POST', '^/api/motivation$', 'salud', 'motivacion', () => 'Registró su motivación'],
  ['POST', '^/api/dietary-control$', 'salud', 'alimentacion', () => 'Registró una comida'],
  ['DELETE', `^/api/dietary-control/${ID}$`, 'salud', 'alimentacion_eliminada', () => 'Eliminó un registro de comida'],

  // --- Entrenamiento ---
  ['POST', '^/api/training-frequency$', 'entrenamiento', 'frecuencia', () => 'Definió su frecuencia de entrenamiento'],
  ['POST', '^/api/training-parameters$', 'entrenamiento', 'parametros', () => 'Definió sus parámetros de entrenamiento'],
  ['POST', '^/api/training-periods$', 'entrenamiento', 'periodo', () => 'Definió su periodo de entrenamiento'],
  ['POST', '^/api/workouts$', 'entrenamiento', 'entrenamiento_registrado', () => 'Registró un entrenamiento'],

  // --- Citas y entrenador ---
  ['POST', '^/api/appointments$', 'citas', 'cita_creada', () => 'Agendó una cita'],
  ['PUT', `^/api/appointments/${ID}/cancelar$`, 'citas', 'cita_cancelada', () => 'Canceló una cita'],
  ['PUT', `^/api/coaches/${ID}/asignarme$`, 'citas', 'entrenador_elegido', () => 'Eligió su entrenador'],
  ['POST', '^/api/coaches/cambio$', 'citas', 'cambio_entrenador', () => 'Solicitó cambiar de entrenador'],
  ['DELETE', `^/api/coaches/cambio/${ID}$`, 'citas', 'cambio_entrenador_cancelado', () => 'Canceló su solicitud de cambio de entrenador'],

  // --- Pagos y plan ---
  ['PUT', `^/api/payments/${ID}/comprobante$`, 'pagos', 'comprobante', () => 'Envió un comprobante de pago'],
  ['POST', '^/api/subscriptions/cambiar-plan$', 'pagos', 'cambio_plan', () => 'Cambió de plan'],

  // --- Comunidad ---
  ['POST', '^/api/community$', 'comunidad', 'publicacion', () => 'Publicó en la comunidad'],
  ['DELETE', `^/api/community/${ID}$`, 'comunidad', 'publicacion_eliminada', () => 'Eliminó una publicación'],
  ['POST', `^/api/community/${ID}/comentarios$`, 'comunidad', 'comentario', () => 'Comentó una publicación'],
  ['DELETE', `^/api/community/${ID}/comentarios/${ID}$`, 'comunidad', 'comentario_eliminado', () => 'Eliminó un comentario'],

  // --- Soporte ---
  ['POST', '^/api/support$', 'soporte', 'ticket', () => 'Abrió una solicitud de soporte'],
  ['POST', `^/api/support/${ID}/mensaje$`, 'soporte', 'ticket_mensaje', () => 'Escribió en una solicitud de soporte'],

  // --- Acciones del equipo (admin) ---
  ['PUT', `^/api/admin/users/(${ID})$`, 'admin', 'admin_edito_usuario', ({ c, o }) => `Editó la cuenta de ${o}${c.length ? ` (${etiquetaCampos(c)})` : ''}`],
  ['PUT', `^/api/admin/users/(${ID})/aprobar$`, 'admin', 'admin_aprobo_cuenta', ({ o }) => `Aprobó la cuenta de ${o}`],
  ['PUT', `^/api/admin/users/(${ID})/rechazar$`, 'admin', 'admin_rechazo_cuenta', ({ o }) => `Rechazó la cuenta de ${o}`],
  ['POST', `^/api/admin/users/(${ID})/revocar$`, 'admin', 'admin_suspendio', ({ o }) => `Revocó (suspendió 1 mes) a ${o}`],
  ['PUT', `^/api/admin/users/(${ID})/reactivar$`, 'admin', 'admin_reactivo', ({ o }) => `Levantó la suspensión de ${o}`],
  ['DELETE', `^/api/admin/users/(${ID})$`, 'admin', 'admin_elimino_usuario', ({ o }) => `Eliminó la cuenta de ${o}`],
  ['PUT', `^/api/admin/subscriptions/${ID}/aprobar$`, 'admin', 'admin_aprobo_pago', () => 'Aprobó un pago / suscripción'],
  ['PUT', `^/api/admin/subscriptions/${ID}/rechazar$`, 'admin', 'admin_rechazo_pago', () => 'Rechazó un pago / suscripción'],
  ['PUT', `^/api/admin/plans/${ID}$`, 'admin', 'admin_edito_plan', () => 'Editó un plan'],
  ['POST', '^/api/admin/groups$', 'admin', 'admin_creo_grupo', () => 'Creó un grupo'],
  ['PUT', `^/api/admin/groups/${ID}$`, 'admin', 'admin_edito_grupo', () => 'Editó un grupo'],
  ['DELETE', `^/api/admin/groups/${ID}$`, 'admin', 'admin_elimino_grupo', () => 'Eliminó un grupo'],
  ['POST', '^/api/admin/notifications$', 'admin', 'admin_anuncio', () => 'Envió un anuncio'],
  ['POST', `^/api/admin/support/${ID}/responder$`, 'admin', 'admin_respondio_ticket', () => 'Respondió una solicitud de soporte'],
  ['PUT', `^/api/admin/support/${ID}/estado$`, 'admin', 'admin_estado_ticket', () => 'Cambió el estado de una solicitud de soporte'],
  ['PUT', `^/api/admin/coach-changes/${ID}/aprobar$`, 'admin', 'admin_aprobo_cambio', () => 'Aprobó un cambio de entrenador'],
  ['PUT', `^/api/admin/coach-changes/${ID}/rechazar$`, 'admin', 'admin_rechazo_cambio', () => 'Rechazó un cambio de entrenador'],
  ['POST', `^/api/admin/expirations/${ID}/avisar$`, 'admin', 'admin_aviso_vencimiento', () => 'Avisó de un vencimiento'],
  ['POST', '^/api/coaches$', 'admin', 'admin_creo_entrenador', () => 'Creó un entrenador'],
  ['PUT', `^/api/coaches/${ID}$`, 'admin', 'admin_edito_entrenador', () => 'Editó un entrenador'],
  ['DELETE', `^/api/coaches/${ID}$`, 'admin', 'admin_elimino_entrenador', () => 'Eliminó un entrenador']
].map(([metodo, rx, categoria, accion, texto]) => ({ metodo, rx: new RegExp(rx), categoria, accion, texto }));

const nombreCorto = (u) => u?.nombre || u?.email || 'un usuario';

export const auditoria = (req, res, next) => {
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) return next();

  const ruta = req.originalUrl.split('?')[0].replace(/\/+$/, '');
  const regla = REGLAS.find((r) => r.metodo === req.method && r.rx.test(ruta));
  if (!regla) return next();

  // Antes de ejecutar: si la cuenta se va a eliminar, todavía se puede leer el nombre
  // de la persona afectada. (Los campos se leen al terminar, cuando multer ya procesó el cuerpo.)
  const idRuta = ruta.match(new RegExp(`/users/(${ID})`))?.[1];

  const objetivoPrevio = idRuta && ruta.startsWith('/api/admin/users')
    ? User.findById(idRuta).select('nombre email').lean().catch(() => null)
    : Promise.resolve(null);

  res.on('finish', async () => {
    if (res.statusCode >= 400 || !req.usuario?.id) return;

    try {
      const campos = camposDe(req.body);
      const foto = !!req.file;
      const objetivo = await objetivoPrevio;
      const actorId = req.usuario.id;

      // Un admin editando el perfil de otra persona cuenta como acción del admin
      const esEdicionAjena = regla.accion === 'perfil_actualizado' && idRuta && idRuta !== String(actorId);
      const o = nombreCorto(objetivo);

      await registrarActividad({
        usuarioId: actorId,
        categoria: esEdicionAjena ? 'admin' : regla.categoria,
        accion: regla.accion,
        descripcion: esEdicionAjena
          ? `Editó el perfil de ${nombreCorto(await User.findById(idRuta).select('nombre email').lean())}`
          : regla.texto({ c: campos, foto, o }),
        objetivoId: objetivo && mongoose.isValidObjectId(idRuta) ? idRuta : undefined,
        objetivoNombre: objetivo ? nombreCorto(objetivo) : undefined,
        detalle: campos.length ? { campos } : undefined
      });
    } catch (error) {
      console.error('⚠️ Historial:', error.message);
    }
  });

  next();
};

export default auditoria;
