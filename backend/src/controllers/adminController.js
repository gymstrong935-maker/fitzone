import mongoose from 'mongoose';
import User from '../models/User.js';
import Plan from '../models/Plan.js';
import Group from '../models/Group.js';
import Coach from '../models/Coach.js';
import Payment from '../models/Payment.js';
import Subscription from '../models/Subscription.js';
import Appointment from '../models/Appointment.js';
import Notification from '../models/Notification.js';
import WorkoutSession from '../models/WorkoutSession.js';
import SupportTicket from '../models/SupportTicket.js';
import { aprobarSuscripcion, rechazarSuscripcion } from './subscriptionController.js';
import { enviarCorreoSeguro } from '../utils/enviarCorreoSeguro.js';
import { correoCuentaAprobada, correoCuentaRechazada } from '../utils/emailTemplates.js';

const OCULTOS = '-passwordHash -resetPasswordToken -resetPasswordExpira -codigoVerificacion -codigoVerificacionExpira';
const escapeRegex = (t) => String(t).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const idValido = (id) => mongoose.isValidObjectId(id);
const enumDe = (campo) => User.schema.path(campo)?.enumValues || [];
const sinUndefined = (obj) => Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== undefined));
const errorServidor = (res, e) => res.status(500).json({ error: e.message });

// ======================================================
// PANEL: ESTADÍSTICAS
// ======================================================

export const obtenerEstadisticas = async (req, res) => {
  try {
    const ahora = new Date();
    const hace7 = new Date(ahora.getTime() - 7 * 24 * 60 * 60 * 1000);
    const inicio6Meses = new Date(ahora.getFullYear(), ahora.getMonth() - 5, 1);
    const hoy = ahora.toISOString().slice(0, 10);

    const [
      totalUsuarios, nuevosSemana, activas, pendientes, entrenadores,
      citasProximas, ticketsAbiertos, entrenamientosSemana, ingresos, porPlan
    ] = await Promise.all([
      User.countDocuments({ rol: { $ne: 'admin' } }),
      User.countDocuments({ rol: { $ne: 'admin' }, fechaRegistro: { $gte: hace7 } }),
      Subscription.countDocuments({ estado: 'activa', fechaFin: { $gt: ahora } }),
      Subscription.countDocuments({ estado: 'pendiente' }),
      Coach.countDocuments(),
      Appointment.countDocuments({ estado: 'confirmada', fecha: { $gte: hoy } }),
      SupportTicket.countDocuments({ estado: { $ne: 'cerrado' } }),
      WorkoutSession.countDocuments({ fecha: { $gte: hace7 } }),
      Payment.aggregate([
        { $match: { estado: 'aprobado' } },
        {
          $facet: {
            total: [{ $group: { _id: null, total: { $sum: '$monto' } } }],
            mensual: [
              { $match: { fechaPago: { $gte: inicio6Meses } } },
              { $group: { _id: { y: { $year: '$fechaPago' }, m: { $month: '$fechaPago' } }, total: { $sum: '$monto' } } }
            ]
          }
        }
      ]),
      Subscription.aggregate([
        { $match: { estado: 'activa', fechaFin: { $gt: ahora } } },
        { $group: { _id: '$planId', total: { $sum: 1 } } },
        { $lookup: { from: 'plans', localField: '_id', foreignField: '_id', as: 'plan' } },
        { $project: { _id: 0, total: 1, nombre: { $ifNull: [{ $arrayElemAt: ['$plan.nombre', 0] }, 'Sin plan'] } } },
        { $sort: { total: -1 } }
      ])
    ]);

    const facet = ingresos[0] || { total: [], mensual: [] };

    const cuentasPendientes = await User.countDocuments({
      estadoCuenta: 'pendiente',
      rol: { $ne: 'admin' }
    });

    const mensuales = [];
    for (let i = 5; i >= 0; i--) {
      const f = new Date(ahora.getFullYear(), ahora.getMonth() - i, 1);
      const hallado = facet.mensual.find((x) => x._id.y === f.getFullYear() && x._id.m === f.getMonth() + 1);
      mensuales.push({ anio: f.getFullYear(), mes: f.getMonth() + 1, total: hallado?.total || 0 });
    }

    res.json({
      usuarios: { total: totalUsuarios, nuevosSemana, pendientes: cuentasPendientes },
      suscripciones: { activas, pendientes },
      entrenadores,
      citasProximas,
      ticketsAbiertos,
      entrenamientosSemana,
      ingresos: { total: facet.total[0]?.total || 0, mensuales },
      planes: porPlan
    });
  } catch (e) {
    errorServidor(res, e);
  }
};

// ======================================================
// USUARIOS
// ======================================================

export const listarUsuarios = async (req, res) => {
  try {
    const { q, rol, estado } = req.query;
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const skip = Math.max(Number(req.query.skip) || 0, 0);

    const filtro = {};
    if (q) {
      const rx = new RegExp(escapeRegex(q), 'i');
      filtro.$or = [{ nombre: rx }, { email: rx }];
    }
    if (rol) filtro.rol = rol;
    if (estado) filtro.estadoCuenta = estado;

    const [usuarios, total] = await Promise.all([
      User.find(filtro)
        .select(OCULTOS)
        .populate('planActual', 'nombre')
        .populate('entrenadorAsignado', 'nombre')
        .sort({ fechaRegistro: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(filtro)
    ]);

    res.json({
      total,
      usuarios,
      opciones: { roles: enumDe('rol'), estados: enumDe('estadoCuenta') }
    });
  } catch (e) {
    errorServidor(res, e);
  }
};

export const detalleUsuario = async (req, res) => {
  try {
    const { id } = req.params;
    if (!idValido(id)) return res.status(400).json({ mensaje: 'Usuario no válido' });

    const usuario = await User.findById(id)
      .select(OCULTOS)
      .populate('planActual', 'nombre')
      .populate('entrenadorAsignado', 'nombre');
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    const [suscripciones, pagos, entrenamientos] = await Promise.all([
      Subscription.find({ usuarioId: id }).populate('planId', 'nombre precio').sort({ _id: -1 }).limit(20),
      Payment.find({ usuarioId: id }).sort({ fechaPago: -1 }).limit(20),
      WorkoutSession.countDocuments({ usuarioId: id })
    ]);

    res.json({
      usuario,
      suscripciones,
      pagos,
      entrenamientos,
      opciones: { roles: enumDe('rol'), estados: enumDe('estadoCuenta') }
    });
  } catch (e) {
    errorServidor(res, e);
  }
};

export const actualizarUsuarioAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    if (!idValido(id)) return res.status(400).json({ mensaje: 'Usuario no válido' });

    const { nombre, telefono, rol, estadoCuenta } = req.body;
    const datos = sinUndefined({ nombre, telefono, rol, estadoCuenta });

    if (id === req.usuario.id && (datos.rol !== undefined || datos.estadoCuenta !== undefined)) {
      return res.status(400).json({ mensaje: 'No puedes cambiar tu propio rol ni el estado de tu cuenta' });
    }

    const roles = enumDe('rol');
    if (datos.rol !== undefined && roles.length && !roles.includes(datos.rol)) {
      return res.status(400).json({ mensaje: 'Rol no válido', permitidos: roles });
    }
    const estados = enumDe('estadoCuenta');
    if (datos.estadoCuenta !== undefined && estados.length && !estados.includes(datos.estadoCuenta)) {
      return res.status(400).json({ mensaje: 'Estado no válido', permitidos: estados });
    }

    const usuario = await User.findByIdAndUpdate(id, datos, { new: true }).select(OCULTOS);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    res.json(usuario);
  } catch (e) {
    errorServidor(res, e);
  }
};

// ======================================================
// SUSCRIPCIONES Y PAGOS
// ======================================================

export const listarSuscripciones = async (req, res) => {
  try {
    const filtro = {};
    if (req.query.estado) filtro.estado = req.query.estado;

    const subs = await Subscription.find(filtro)
      .populate('usuarioId', 'nombre email')
      .populate('planId', 'nombre precio duracionDias esGratuito')
      .sort({ _id: -1 })
      .limit(200);

    const pagos = await Payment.find({ suscripcionId: { $in: subs.map((s) => s._id) } });
    const porSuscripcion = new Map(pagos.map((p) => [String(p.suscripcionId), p]));

    res.json(subs.map((s) => ({ ...s.toObject(), pago: porSuscripcion.get(String(s._id)) || null })));
  } catch (e) {
    errorServidor(res, e);
  }
};

// Aprobar / rechazar: se reutiliza la lógica existente y además se actualiza el pago
export const aprobarConPago = async (req, res) => {
  await aprobarSuscripcion(req, res);
  if (res.statusCode < 400) {
    try {
      await Payment.updateMany(
        { suscripcionId: req.params.id, estado: 'pendiente' },
        { $set: { estado: 'aprobado' } }
      );
    } catch (e) {
      console.error('❌ No se pudo actualizar el pago:', e.message);
    }
  }
};

export const rechazarConPago = async (req, res) => {
  await rechazarSuscripcion(req, res);
  if (res.statusCode < 400) {
    try {
      await Payment.updateMany(
        { suscripcionId: req.params.id, estado: 'pendiente' },
        { $set: { estado: 'rechazado' } }
      );
    } catch (e) {
      console.error('❌ No se pudo actualizar el pago:', e.message);
    }
  }
};

export const listarPagos = async (req, res) => {
  try {
    const filtro = {};
    if (req.query.estado) filtro.estado = req.query.estado;

    const pagos = await Payment.find(filtro)
      .populate('usuarioId', 'nombre email')
      .populate({ path: 'suscripcionId', populate: { path: 'planId', select: 'nombre' } })
      .sort({ fechaPago: -1 })
      .limit(200);

    res.json(pagos);
  } catch (e) {
    errorServidor(res, e);
  }
};

// ======================================================
// PLANES (listar y editar)
// ======================================================

export const listarPlanes = async (req, res) => {
  try {
    res.json(await Plan.find().sort({ precio: 1 }));
  } catch (e) {
    errorServidor(res, e);
  }
};

export const actualizarPlan = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Plan no válido' });

    const plan = await Plan.findById(req.params.id);
    if (!plan) return res.status(404).json({ mensaje: 'Plan no encontrado' });

    const { nombre, precio, duracionDias, beneficios } = req.body;
    plan.nombre = nombre;
    plan.precio = plan.esGratuito ? 0 : precio;   // el plan gratuito siempre cuesta 0
    plan.duracionDias = duracionDias;
    plan.beneficios = beneficios;

    await plan.save();
    res.json(plan);
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ mensaje: 'Ya existe un plan con ese nombre' });
    errorServidor(res, e);
  }
};

// ======================================================
// GRUPOS
// ======================================================

export const listarGrupos = async (req, res) => {
  try {
    const grupos = await Group.find().populate('entrenadorId', 'nombre').sort({ nombre: 1 });
    res.json(grupos.map((g) => ({ ...g.toObject(), totalMiembros: g.miembros.length })));
  } catch (e) {
    errorServidor(res, e);
  }
};

export const crearGrupo = async (req, res) => {
  try {
    const { nombre, nivel, horario, entrenadorId } = req.body;
    if (entrenadorId && !idValido(entrenadorId)) return res.status(400).json({ mensaje: 'Entrenador no válido' });

    const grupo = await Group.create(sinUndefined({ nombre, nivel, horario, entrenadorId: entrenadorId || undefined }));
    res.status(201).json(grupo);
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ mensaje: 'Ya existe un grupo con ese nombre' });
    errorServidor(res, e);
  }
};

export const actualizarGrupo = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Grupo no válido' });

    const { nombre, nivel, horario, entrenadorId } = req.body;
    if (entrenadorId && !idValido(entrenadorId)) return res.status(400).json({ mensaje: 'Entrenador no válido' });

    const grupo = await Group.findByIdAndUpdate(
      req.params.id,
      { nombre, nivel, horario, entrenadorId: entrenadorId || null },
      { new: true }
    );
    if (!grupo) return res.status(404).json({ mensaje: 'Grupo no encontrado' });

    res.json(grupo);
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ mensaje: 'Ya existe un grupo con ese nombre' });
    errorServidor(res, e);
  }
};

export const eliminarGrupo = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Grupo no válido' });

    const grupo = await Group.findByIdAndDelete(req.params.id);
    if (!grupo) return res.status(404).json({ mensaje: 'Grupo no encontrado' });

    res.json({ mensaje: 'Grupo eliminado' });
  } catch (e) {
    errorServidor(res, e);
  }
};

// ======================================================
// CITAS
// ======================================================

export const listarCitas = async (req, res) => {
  try {
    const filtro = {};
    if (req.query.estado) filtro.estado = req.query.estado;
    if (req.query.desde) filtro.fecha = { $gte: req.query.desde };

    const citas = await Appointment.find(filtro)
      .populate('usuarioId', 'nombre email')
      .populate('entrenadorId', 'nombre')
      .sort({ fecha: 1, hora: 1 })
      .limit(300);

    res.json(citas);
  } catch (e) {
    errorServidor(res, e);
  }
};

// ======================================================
// ANUNCIOS (notificaciones masivas o a un usuario)
// ======================================================

export const enviarAnuncio = async (req, res) => {
  try {
    const { destino, email, tipo, mensaje } = req.body;
    let ids = [];

    if (destino === 'usuario') {
      const usuario = await User.findOne({ email });
      if (!usuario) return res.status(404).json({ mensaje: 'No existe un usuario con ese correo' });
      ids = [usuario._id];
    } else if (destino === 'activos') {
      ids = await Subscription.distinct('usuarioId', { estado: 'activa', fechaFin: { $gt: new Date() } });
    } else {
      ids = await User.distinct('_id', { rol: { $ne: 'admin' } });
    }

    if (!ids.length) return res.status(400).json({ mensaje: 'No hay usuarios destinatarios' });

    const lote = ids.slice(0, 5000);
    await Notification.insertMany(lote.map((usuarioId) => ({ usuarioId, tipo, mensaje })));

    res.status(201).json({ enviadas: lote.length });
  } catch (e) {
    errorServidor(res, e);
  }
};

// ======================================================
// SOPORTE (bandeja del administrador)
// ======================================================

export const listarTickets = async (req, res) => {
  try {
    const filtro = {};
    if (req.query.estado) filtro.estado = req.query.estado;

    const tickets = await SupportTicket.find(filtro)
      .select('-transcripcion')
      .populate('usuarioId', 'nombre email')
      .sort({ updatedAt: -1 })
      .limit(200);

    res.json(tickets);
  } catch (e) {
    errorServidor(res, e);
  }
};

export const detalleTicket = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Solicitud no válida' });

    const ticket = await SupportTicket.findById(req.params.id).populate('usuarioId', 'nombre email');
    if (!ticket) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });

    res.json(ticket);
  } catch (e) {
    errorServidor(res, e);
  }
};

export const responderTicket = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Solicitud no válida' });

    const ticket = await SupportTicket.findById(req.params.id);
    if (!ticket) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });

    ticket.respuestas.push({ autor: 'admin', mensaje: req.body.mensaje });
    ticket.estado = req.body.estado || (ticket.estado === 'abierto' ? 'en_proceso' : ticket.estado);
    await ticket.save();

    await Notification.create({
      usuarioId: ticket.usuarioId,
      tipo: 'sistema',
      mensaje: `Soporte respondió a tu solicitud "${ticket.asunto}".`
    });

    const completo = await SupportTicket.findById(ticket._id).populate('usuarioId', 'nombre email');
    res.json(completo);
  } catch (e) {
    errorServidor(res, e);
  }
};

export const cambiarEstadoTicket = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Solicitud no válida' });

    const ticket = await SupportTicket
      .findByIdAndUpdate(req.params.id, { estado: req.body.estado }, { new: true })
      .populate('usuarioId', 'nombre email');
    if (!ticket) return res.status(404).json({ mensaje: 'Solicitud no encontrada' });

    res.json(ticket);
  } catch (e) {
    errorServidor(res, e);
  }
};

// ======================================================
// APROBAR / RECHAZAR CUENTAS NUEVAS
// ======================================================

export const aprobarCuenta = async (req, res) => {
  try {
    const { id } = req.params;
    if (!idValido(id)) return res.status(400).json({ mensaje: 'Usuario no válido' });

    const usuario = await User.findById(id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    if (usuario.estadoCuenta === 'activo') {
      return res.status(400).json({ mensaje: 'La cuenta ya está activa' });
    }
    if (!['pendiente', 'rechazado'].includes(usuario.estadoCuenta)) {
      return res.status(400).json({ mensaje: 'Solo se pueden aprobar cuentas pendientes o rechazadas' });
    }

    usuario.estadoCuenta = 'activo';
    usuario.motivoRechazo = undefined;
    await usuario.save();

    // La prueba gratuita empieza a contar desde que se aprueba la cuenta
    const suscripcion = await Subscription
      .findOne({ usuarioId: usuario._id })
      .sort({ _id: -1 })
      .populate('planId', 'esGratuito duracionDias');

    if (suscripcion?.planId?.esGratuito) {
      const inicio = new Date();
      suscripcion.fechaInicio = inicio;
      suscripcion.fechaFin = new Date(inicio.getTime() + suscripcion.planId.duracionDias * 24 * 60 * 60 * 1000);
      suscripcion.estado = 'activa';
      await suscripcion.save();
    }

    await Notification.create({
      usuarioId: usuario._id,
      tipo: 'sistema',
      mensaje: '¡Tu cuenta fue aprobada! Ya puedes continuar en FitZone.'
    });

    const correo = correoCuentaAprobada({ nombre: usuario.nombre });
    await enviarCorreoSeguro({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: correo.asunto,
      html: correo.html
    });

    res.json({ mensaje: 'Cuenta aprobada', usuario });
  } catch (e) {
    errorServidor(res, e);
  }
};

export const rechazarCuenta = async (req, res) => {
  try {
    const { id } = req.params;
    if (!idValido(id)) return res.status(400).json({ mensaje: 'Usuario no válido' });
    if (id === req.usuario.id) return res.status(400).json({ mensaje: 'No puedes rechazar tu propia cuenta' });

    const usuario = await User.findById(id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    if (usuario.rol === 'admin') return res.status(400).json({ mensaje: 'No se puede rechazar a un administrador' });
    if (usuario.estadoCuenta !== 'pendiente') {
      return res.status(400).json({ mensaje: 'Solo se pueden rechazar cuentas pendientes' });
    }

    const motivo = (req.body.motivo || '').trim();

    usuario.estadoCuenta = 'rechazado';
    usuario.motivoRechazo = motivo || undefined;
    await usuario.save();

    await Notification.create({
      usuarioId: usuario._id,
      tipo: 'sistema',
      mensaje: motivo
        ? `Tu solicitud de registro no fue aprobada. Motivo: ${motivo}`
        : 'Tu solicitud de registro no fue aprobada.'
    });

    const correo = correoCuentaRechazada({ nombre: usuario.nombre, motivo });
    await enviarCorreoSeguro({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: correo.asunto,
      html: correo.html
    });

    res.json({ mensaje: 'Cuenta rechazada', usuario });
  } catch (e) {
    errorServidor(res, e);
  }
};