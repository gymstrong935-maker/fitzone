import Subscription from '../models/Subscription.js';
import Notification from '../models/Notification.js';
import { enviarCorreoSeguro } from '../utils/enviarCorreoSeguro.js';
import { correoAviso, escapeHtml } from '../utils/emailTemplates.js';

const MS_DIA = 24 * 60 * 60 * 1000;

// Días que faltan (positivo) o que pasaron (negativo) respecto a ahora
const diasHasta = (fecha, ahora = new Date()) =>
  Math.ceil((new Date(fecha).getTime() - ahora.getTime()) / MS_DIA);

const fechaCorta = (f) =>
  new Date(f).toLocaleDateString('es-CO', { day: '2-digit', month: '2-digit', year: 'numeric' });

const fila = (sub, ahora) => ({
  suscripcionId: String(sub._id),
  usuarioId: sub.usuarioId?._id ? String(sub.usuarioId._id) : null,
  nombre: sub.usuarioId?.nombre || '(usuario eliminado)',
  email: sub.usuarioId?.email || '',
  plan: sub.planId?.nombre || '—',
  esGratuito: !!sub.planId?.esGratuito,
  fechaFin: sub.fechaFin,
  dias: sub.fechaFin ? diasHasta(sub.fechaFin, ahora) : null
});

const poblar = (consulta) =>
  consulta
    .populate('usuarioId', 'nombre email estadoCuenta rol')
    .populate('planId', 'nombre esGratuito');

// ¿Este usuario ya tiene una suscripción posterior (renovó o está por aprobarse)?
const renovada = async (sub) =>
  !!(await Subscription.exists({
    usuarioId: sub.usuarioId?._id || sub.usuarioId,
    _id: { $gt: sub._id },
    estado: { $in: ['activa', 'pendiente'] }
  }));

// ======================================================
// LISTADO (solo lectura) para la pantalla "Vencimientos"
// ======================================================

export const listarVencimientos = async ({ ventanaDias = 7 } = {}) => {
  const ahora = new Date();
  const limite = new Date(ahora.getTime() + ventanaDias * MS_DIA);

  const porVencerSubs = await poblar(
    Subscription.find({ estado: 'activa', fechaFin: { $gte: ahora, $lte: limite } }).sort({ fechaFin: 1 })
  );

  const desde = new Date(ahora.getTime() - 90 * MS_DIA);

  const vencidasSubs = await poblar(
    Subscription.find({
      $or: [
        { estado: 'vencida' },
        { estado: 'activa', fechaFin: { $lt: ahora } }
      ],
      fechaFin: { $gte: desde, $lt: ahora }
    }).sort({ fechaFin: -1 })
  );

  const vencidas = [];
  for (const sub of vencidasSubs) {
    if (!sub.usuarioId || sub.usuarioId.rol === 'admin') continue;
    if (await renovada(sub)) continue; // ya renovó: no es un caso pendiente
    vencidas.push(fila(sub, ahora));
  }

  return {
    ventanaDias,
    generadoEn: ahora,
    porVencer: porVencerSubs.filter((s) => s.usuarioId?.rol !== 'admin').map((s) => fila(s, ahora)),
    vencidas
  };
};

// ======================================================
// AVISOS
// ======================================================

const textoRecordatorio = (f) => {
  const cuando =
    f.dias <= 0 ? 'vence hoy' : f.dias === 1 ? 'vence mañana' : `vence en ${f.dias} días`;
  return `Tu plan ${f.plan} ${cuando} (${fechaCorta(f.fechaFin)}). Renueva para no perder el acceso.`;
};

const textoVencida = (f) =>
  `Tu plan ${f.plan} venció el ${fechaCorta(f.fechaFin)}. Elige un plan para volver a entrenar.`;

// Crea la notificación (y el correo) solo si no se envió ya exactamente el mismo aviso
const avisarUsuario = async (f, mensaje, asunto) => {
  if (!f.usuarioId) return false;

  const repetido = await Notification.exists({
    usuarioId: f.usuarioId,
    tipo: 'recordatorio',
    mensaje
  });
  if (repetido) return false;

  await Notification.create({ usuarioId: f.usuarioId, tipo: 'recordatorio', mensaje, leida: false });

  if (f.email) {
    await enviarCorreoSeguro({
      from: process.env.EMAIL_USER,
      to: f.email,
      subject: asunto,
      html: correoAviso({
        titulo: asunto,
        contenidoHtml: `<p>Hola ${escapeHtml(f.nombre)},</p><p>${escapeHtml(mensaje)}</p>`
      })
    });
  }
  return true;
};

// ======================================================
// REVISIÓN COMPLETA (la ejecuta el cron y el botón del admin)
//  1) marca como vencidas las suscripciones cuya fecha ya pasó
//  2) avisa a quienes vencen en los próximos días
//  3) avisa a quienes acaban de vencer
// ======================================================

export const ejecutarRevisionVencimientos = async ({ ventanaDias = 3 } = {}) => {
  const ahora = new Date();
  const limite = new Date(ahora.getTime() + ventanaDias * MS_DIA);

  // 1) Vencidas ahora
  const porMarcar = await poblar(
    Subscription.find({ estado: 'activa', fechaFin: { $lt: ahora } })
  );

  if (porMarcar.length) {
    await Subscription.updateMany(
      { _id: { $in: porMarcar.map((s) => s._id) } },
      { $set: { estado: 'vencida' } }
    );
  }

  const vencidasAhora = [];
  let avisosVencidas = 0;

  for (const sub of porMarcar) {
    if (sub.usuarioId?.rol === 'admin') continue;
    const f = fila(sub, ahora);
    vencidasAhora.push(f);
    if (await avisarUsuario(f, textoVencida(f), 'FitZone - Tu plan venció')) avisosVencidas++;
  }

  // 2) Por vencer
  const porVencerSubs = await poblar(
    Subscription.find({ estado: 'activa', fechaFin: { $gte: ahora, $lte: limite } }).sort({ fechaFin: 1 })
  );

  const porVencer = [];
  let avisosPorVencer = 0;

  for (const sub of porVencerSubs) {
    if (sub.usuarioId?.rol === 'admin') continue;
    const f = fila(sub, ahora);
    const avisado = await avisarUsuario(f, textoRecordatorio(f), 'FitZone - Tu plan está por vencer');
    if (avisado) avisosPorVencer++;
    porVencer.push({ ...f, avisado });
  }

  return {
    mensaje: 'Verificación completada',
    ventanaDias,
    revisadas: porMarcar.length + porVencerSubs.length,
    suscripcionesVencidas: vencidasAhora.length,
    notificacionesEnviadas: avisosPorVencer + avisosVencidas,
    avisosPorVencer,
    avisosVencidas,
    vencidasAhora,
    porVencer
  };
};

// Recordatorio manual a un usuario concreto (botón "Notificar")
export const notificarVencimiento = async (suscripcionId) => {
  const sub = await poblar(Subscription.findById(suscripcionId));
  if (!sub || !sub.usuarioId) return { ok: false, mensaje: 'Suscripción no encontrada' };

  const f = fila(sub, new Date());
  const vencida = f.dias !== null && f.dias < 0;
  const mensaje = vencida ? textoVencida(f) : textoRecordatorio(f);

  // Manual: siempre se envía (si ya existía igual, se registra con la hora para no chocar)
  await Notification.create({
    usuarioId: f.usuarioId,
    tipo: 'recordatorio',
    mensaje,
    leida: false
  });

  if (f.email) {
    await enviarCorreoSeguro({
      from: process.env.EMAIL_USER,
      to: f.email,
      subject: vencida ? 'FitZone - Tu plan venció' : 'FitZone - Tu plan está por vencer',
      html: correoAviso({
        titulo: vencida ? 'Tu plan venció' : 'Tu plan está por vencer',
        contenidoHtml: `<p>Hola ${escapeHtml(f.nombre)},</p><p>${escapeHtml(mensaje)}</p>`
      })
    });
  }

  return { ok: true, mensaje: `Aviso enviado a ${f.nombre}` };
};
