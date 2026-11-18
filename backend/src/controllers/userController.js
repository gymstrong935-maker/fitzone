import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { OAuth2Client } from 'google-auth-library';

import User from '../models/User.js';
import Plan from '../models/Plan.js';
import transporter from '../utils/mailer.js';
import mongoose from 'mongoose';
import { crearSuscripcionParaPlan, planBloqueante } from '../helpers/suscripciones.js';
import { borrarImagenCloudinary } from '../utils/cloudinary.js';
import { enviarCorreoSeguro } from '../utils/enviarCorreoSeguro.js';
import notificarAdmin from '../helpers/notificarAdmin.js';
import {
  MINUTOS_CODIGO,
  correoVerificacion,
  correoRecuperacion,
  correoCambioEmail,
  correoEmailCambiado,
  escapeHtml
} from '../utils/emailTemplates.js';
import RevokedAccount from '../models/RevokedAccount.js';
import { levantarSiVencio, estaBloqueada, respuestaSuspension } from '../helpers/suspension.js';
import { registrarActividad } from '../utils/actividad.js';
import { eliminarCuentaYDatos } from '../helpers/eliminarCuentaUsuario.js';

const googleClient = new OAuth2Client();

// Códigos de 6 dígitos (criptográficamente aleatorios) que vencen en MINUTOS_CODIGO
const crearCodigo = () => crypto.randomInt(100000, 1000000).toString();

// Se guarda solo el hash (SHA-256) del código
const hashCodigo = (codigo) =>
  crypto.createHash('sha256').update(String(codigo)).digest('hex');

const MSG_REVOCADA =
  'Tu cuenta fue revocada por el equipo de FitZone. Si crees que es un error, escríbenos por los canales oficiales.';
const vencimientoCodigo = () => Date.now() + MINUTOS_CODIGO * 60 * 1000;

// Espera máxima (ms) para enviar un correo antes de responder igual a la app
const ESPERA_MAXIMA_CORREO = 8000;

// Envía un correo sin dejar colgada la respuesta: devuelve true/false
const enviarSinBloquear = (datos) =>
  Promise.race([
    enviarCorreoSeguro(datos)
      .then((ok) => !!ok)
      .catch((err) => {
        console.error('⚠️ Falló el envío del correo:', err.message);
        return false;
      }),
    new Promise((resolve) => setTimeout(() => resolve(false), ESPERA_MAXIMA_CORREO))
  ]);

// Busca por correo sin distinguir mayúsculas: así también entran las cuentas
// creadas antes de que los correos se guardaran en minúsculas.
const buscarPorEmail = async (email) => {
  const limpio = String(email || '').trim().toLowerCase();
  if (!limpio) return null;

  return (
    (await User.findOne({ email: limpio })) ||
    (await User.findOne({ email: String(email).trim() }).collation({ locale: 'en', strength: 2 }))
  );
};

// ======================================================
// REGISTRAR USUARIO
// ======================================================

export const registrarUsuario = async (req, res) => {
  try {
    const {
      nombre,
      email,
      password,
      telefono,
      planId,
      metodoPago
    } = req.body;

    const emailLimpio = String(email || '').toLowerCase().trim();

    if (!nombre || !emailLimpio || !password) {
      return res.status(400).json({
        mensaje: 'Nombre, correo y contraseña son obligatorios'
      });
    }

    // Cuentas revocadas por el equipo no pueden volver a registrarse
    const revocada = await RevokedAccount.findOne({ email: emailLimpio });
    if (revocada) {
      return res.status(403).json({ mensaje: MSG_REVOCADA, codigo: 'CUENTA_REVOCADA' });
    }

    // Si el correo ya existe y está verificado, no se puede repetir.
    // Si quedó a medias (nunca verificó), se descarta y se registra de nuevo.
    const existe = await buscarPorEmail(emailLimpio);

    if (existe && existe.cuentaVerificada !== false) {
      return res.status(400).json({
        mensaje: 'El correo ya está registrado'
      });
    }

    if (existe) {
      await User.deleteOne({ _id: existe._id });
    }

    const plan = planId
      ? await Plan.findById(planId)
      : await Plan.findOne({ esGratuito: true });

    if (!plan) {
      return res.status(404).json({
        mensaje: 'Plan no encontrado'
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const codigoVerificacion = crearCodigo();

    const nuevoUsuario = await User.create({
      nombre,
      email: emailLimpio,
      passwordHash,
      telefono,
      planActual: plan._id,
      cuentaVerificada: false,
      estadoCuenta: 'pendiente', // el equipo debe aprobar la cuenta
      codigoVerificacion: hashCodigo(codigoVerificacion),
      codigoVerificacionExpira: vencimientoCodigo()
    });

    await crearSuscripcionParaPlan(nuevoUsuario, plan, metodoPago);

    if (process.env.NODE_ENV !== 'production') {
      console.log(`🔐 [DEV] Código de verificación de ${nuevoUsuario.email}: ${codigoVerificacion}`);
    }

    const correo = correoVerificacion({
      nombre: nuevoUsuario.nombre,
      codigo: codigoVerificacion
    });

    const correoEnviado = await enviarSinBloquear({
      from: process.env.EMAIL_USER,
      to: nuevoUsuario.email,
      subject: correo.asunto,
      html: correo.html
    });

    registrarActividad({
      usuarioId: nuevoUsuario._id, nombre: nuevoUsuario.nombre, email: nuevoUsuario.email, rol: nuevoUsuario.rol,
      categoria: 'cuenta', accion: 'registro', descripcion: 'Creó su cuenta'
    });

    return res.status(201).json({
      mensaje: correoEnviado
        ? 'Cuenta creada. Revisa tu correo para verificarla; después el equipo de FitZone aprobará tu cuenta.'
        : 'Cuenta creada, pero no pudimos enviar el correo con el código. Pulsa "Reenviar código" en unos segundos.',
      correoEnviado,
      usuario: nuevoUsuario
    });

  } catch (error) {
    console.error('❌ Error al registrar usuario:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// VERIFICAR CUENTA
// ======================================================

export const verificarCuenta = async (req, res) => {
  try {
    const { email, codigo } = req.body;

    const usuario = await buscarPorEmail(email);

    if (!usuario) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    if (usuario.cuentaVerificada) {
      return res.status(400).json({
        mensaje: 'La cuenta ya está verificada'
      });
    }

    // Se acepta el código cifrado (nuevo) o en texto (cuentas creadas antes)
    const coincide =
      !!usuario.codigoVerificacion &&
      [hashCodigo(codigo), codigo].includes(usuario.codigoVerificacion);

    if (
      !coincide ||
      !usuario.codigoVerificacionExpira ||
      usuario.codigoVerificacionExpira < Date.now()
    ) {
      return res.status(400).json({
        mensaje: 'Código inválido o expirado'
      });
    }

    usuario.cuentaVerificada = true;
    usuario.codigoVerificacion = undefined;
    usuario.codigoVerificacionExpira = undefined;

    await usuario.save();

    // Ahora sí: hay una cuenta verificada esperando aprobación
    if (usuario.estadoCuenta === 'pendiente') {
      await notificarAdmin({
        mensaje: `Nueva cuenta por aprobar: ${usuario.nombre} (${usuario.email}).`,
        asuntoCorreo: 'Nueva cuenta por aprobar',
        htmlCorreo: `
          <p>Se registró y verificó su correo <strong>${escapeHtml(usuario.nombre)}</strong> (${escapeHtml(usuario.email)}).</p>
          <p>Entra al panel administrativo, sección <strong>Usuarios</strong>, para aprobar o rechazar la cuenta.</p>
        `
      });
    }

    return res.json({
      mensaje: 'Cuenta verificada correctamente'
    });

  } catch (error) {
    console.error('❌ Error al verificar cuenta:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// REENVIAR CÓDIGO
// ======================================================

export const reenviarCodigo = async (req, res) => {
  try {
    const { email } = req.body;

    const usuario = await buscarPorEmail(email);

    if (!usuario) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    if (usuario.cuentaVerificada) {
      return res.status(400).json({
        mensaje: 'La cuenta ya está verificada'
      });
    }

    const codigoVerificacion = crearCodigo();

    usuario.codigoVerificacion = hashCodigo(codigoVerificacion);
    usuario.codigoVerificacionExpira = vencimientoCodigo();

    await usuario.save();

    if (process.env.NODE_ENV !== 'production') {
      console.log(`🔐 [DEV] Nuevo código de ${usuario.email}: ${codigoVerificacion}`);
    }

    const correo = correoVerificacion({
      nombre: usuario.nombre,
      codigo: codigoVerificacion,
      reenvio: true
    });

    const enviado = await enviarSinBloquear({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: correo.asunto,
      html: correo.html
    });

    if (!enviado) {
      return res.status(502).json({
        mensaje: 'No pudimos enviar el correo en este momento. Inténtalo de nuevo en unos segundos.',
        codigo: 'CORREO_NO_ENVIADO'
      });
    }

    return res.json({
      mensaje: 'Código reenviado correctamente'
    });

  } catch (error) {
    console.error('❌ Error al reenviar código:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// REGLA DE PLAN: quien se registró con un plan solo entra con ese plan mientras su
// inscripción siga vigente (o pendiente). Los admins no tienen esta regla.
// Devuelve el cuerpo del error 409 o null si puede entrar.
// ======================================================

const conflictoDePlan = async (usuario, planElegidoId) => {
  if (!planElegidoId || usuario.rol === 'admin') return null;

  const bloqueo = await planBloqueante(usuario._id);

  if (bloqueo && String(bloqueo.planId) !== String(planElegidoId)) {
    const planPropio = await Plan.findById(bloqueo.planId).select('nombre');

    return {
      mensaje:
        `Tu cuenta está registrada con el plan ${planPropio?.nombre || 'anterior'}. ` +
        'Solo puedes ingresar con ese plan hasta que termine tu inscripción.',
      codigo: 'PLAN_DISTINTO',
      planActual: planPropio?.nombre,
      planActualId: String(bloqueo.planId),
      vigenteHasta: bloqueo.fechaFin || undefined
    };
  }

  return null;
};


// ======================================================
// LOGIN
// ======================================================

export const iniciarSesion = async (req, res) => {
  try {
    const { email, password, planId } = req.body;

    const usuario = await buscarPorEmail(email);

    if (!usuario) {
      const revocada = await RevokedAccount.findOne({ email: String(email).toLowerCase().trim() });

      if (revocada) {
        return res.status(403).json({
          mensaje: MSG_REVOCADA,
          codigo: 'CUENTA_REVOCADA',
          motivo: revocada.motivo || undefined
        });
      }

      return res.status(401).json({
        mensaje: 'Correo o contraseña incorrectos'
      });
    }

    if (!usuario.passwordHash) {
      return res.status(400).json({
        mensaje:
          'Esta cuenta se creó con Google. Entra con "Continuar con Google" o crea una contraseña con "¿Olvidaste tu contraseña?".'
      });
    }

    const passwordValido = await bcrypt.compare(
      password,
      usuario.passwordHash
    );

    if (!passwordValido) {
      return res.status(401).json({
        mensaje: 'Correo o contraseña incorrectos'
      });
    }

    if (usuario.cuentaVerificada === false) {
      return res.status(403).json({
        mensaje: 'Debes verificar tu cuenta antes de iniciar sesión',
        codigo: 'CUENTA_NO_VERIFICADA'
      });
    }

    // Suspendidas o inactivas no entran. Las pendientes o rechazadas sí reciben
    // sesión para ver su estado, pero el servidor les bloquea el resto (authMiddleware).
    await levantarSiVencio(usuario); // si el baneo de 1 mes ya terminó, vuelve a estar activa

    if (estaBloqueada(usuario)) {
      return res.status(403).json(respuestaSuspension(usuario));
    }

    // Solo entra con el plan con el que se registró (mientras siga vigente)
    if (mongoose.isValidObjectId(planId)) {
      const conflicto = await conflictoDePlan(usuario, planId);
      if (conflicto) return res.status(409).json(conflicto);
    }

    const token = jwt.sign(
      {
        id: usuario._id,
        rol: usuario.rol
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '7d'
      }
    );

    registrarActividad({
      usuarioId: usuario._id, nombre: usuario.nombre, email: usuario.email, rol: usuario.rol,
      categoria: 'cuenta', accion: 'inicio_sesion', descripcion: 'Inició sesión'
    });

    return res.json({
      mensaje: 'Sesión iniciada',
      token,
      usuario
    });

  } catch (error) {
    console.error('❌ Error al iniciar sesión:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// LOGIN CON GOOGLE
// ======================================================
//
// La app obtiene un ID token de Google (google_sign_in) y lo envía aquí.
// Se valida contra GOOGLE_SERVER_CLIENT_ID (ID de cliente "Web" de Google
// Cloud). Se pueden indicar varios separados por coma (p. ej. Web + otro).
//
// Reglas de la cuenta (las mismas que el login normal):
//  - revocada / suspendida / inactiva → no entra
//  - nueva → queda "pendiente" y el equipo debe aprobarla; recibe sesión
//    para ver la pantalla de revisión (authMiddleware bloquea el resto)

const clientIdsGoogle = () =>
  [process.env.GOOGLE_SERVER_CLIENT_ID, process.env.GOOGLE_ANDROID_CLIENT_ID, process.env.GOOGLE_WEB_CLIENT_ID]
    .filter(Boolean)
    .join(',')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);

// Avisa al equipo que hay una cuenta (verificada por Google) por aprobar
const notificarNuevaCuentaGoogle = async (usuario) => {
  try {
    await notificarAdmin({
      mensaje: `Nueva cuenta por aprobar: ${usuario.nombre} (${usuario.email}).`,
      asuntoCorreo: 'Nueva cuenta por aprobar',
      htmlCorreo: `
        <p>Se registró con Google <strong>${escapeHtml(usuario.nombre)}</strong> (${escapeHtml(usuario.email)}).</p>
        <p>Entra al panel administrativo, sección <strong>Usuarios</strong>, para aprobar o rechazar la cuenta.</p>
      `
    });
  } catch (error) {
    // Que falle el aviso no debe impedir el inicio de sesión
    console.error('⚠️ No se pudo notificar al admin:', error.message);
  }
};

export const iniciarSesionGoogle = async (req, res) => {
  try {
    const { idToken, planId } = req.body || {};

    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({
        mensaje: 'El ID token de Google es obligatorio'
      });
    }

    const audiencias = clientIdsGoogle();

    if (audiencias.length === 0) {
      console.error('❌ GOOGLE_SERVER_CLIENT_ID no está configurado en .env');

      return res.status(500).json({
        mensaje: 'El inicio de sesión con Google no está configurado en el servidor'
      });
    }

    // 1) Validar el token con Google (firma, vigencia y audiencia).
    let payload;

    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: audiencias
      });

      payload = ticket.getPayload();
    } catch (error) {
      console.error(
        '❌ Token de Google rechazado:', error.message,
        '| audiencias aceptadas:', audiencias.length
      );

      return res.status(401).json({
        mensaje: 'No se pudo validar la cuenta de Google. Inténtalo de nuevo.',
        codigo: 'GOOGLE_TOKEN_INVALIDO'
      });
    }

    if (!payload) {
      return res.status(401).json({
        mensaje: 'Token de Google inválido'
      });
    }

    const {
      sub: googleId,
      name,
      picture,
      email_verified: emailVerificado
    } = payload;

    const email = String(payload.email || '').toLowerCase().trim();

    if (!email || !googleId) {
      return res.status(401).json({
        mensaje: 'Google no proporcionó los datos necesarios'
      });
    }

    if (!emailVerificado) {
      return res.status(403).json({
        mensaje: 'El correo de tu cuenta de Google no está verificado'
      });
    }

    // 2) Cuentas revocadas por el equipo no pueden volver a entrar
    const revocada = await RevokedAccount.findOne({ email });

    if (revocada) {
      return res.status(403).json({
        mensaje: MSG_REVOCADA,
        codigo: 'CUENTA_REVOCADA',
        motivo: revocada.motivo || undefined
      });
    }

    // 3) Plan que eligió en la pantalla (opcional al iniciar sesión,
    //    obligatorio para crear una cuenta nueva)
    let planElegido = null;

    if (planId) {
      if (!mongoose.isValidObjectId(planId)) {
        return res.status(400).json({ mensaje: 'El plan elegido no es válido' });
      }

      planElegido = await Plan.findById(planId);

      if (!planElegido) {
        return res.status(404).json({ mensaje: 'El plan elegido ya no existe' });
      }
    }

    // 4) Buscar la cuenta (por Google o por correo) o crearla
    let usuario =
      (await User.findOne({ googleId })) || (await buscarPorEmail(email));

    let esNueva = false;

    if (usuario) {
      if (usuario.googleId && usuario.googleId !== googleId) {
        return res.status(409).json({
          mensaje: 'El correo está asociado a otra cuenta de Google'
        });
      }

      // 4a) REGLA DE PLAN (la misma que en el login por correo)
      if (planElegido) {
        const conflicto = await conflictoDePlan(usuario, planElegido._id);
        if (conflicto) return res.status(409).json(conflicto);
      }

      // Cuenta existente: se vincula con Google (Google ya confirmó el correo).
      if (!usuario.googleId) {
        usuario.googleId = googleId;

        if (!usuario.passwordHash) {
          usuario.proveedorAuth = 'google';
        }

        if (!usuario.fotoPerfil && picture) {
          usuario.fotoPerfil = picture;
        }
      }

      const eraNoVerificada = usuario.cuentaVerificada === false;

      if (eraNoVerificada) {
        usuario.cuentaVerificada = true;
        usuario.codigoVerificacion = undefined;
        usuario.codigoVerificacionExpira = undefined;
      }

      await usuario.save();

      if (eraNoVerificada && usuario.estadoCuenta === 'pendiente') {
        await notificarNuevaCuentaGoogle(usuario);
      }

    } else {
      // Cuenta nueva: necesita un plan elegido
      if (!planElegido) {
        return res.status(404).json({
          mensaje: 'No encontramos una cuenta con ese correo. Elige un plan para registrarte.',
          codigo: 'CUENTA_NO_EXISTE'
        });
      }

      // estadoCuenta queda "pendiente" (valor por defecto del modelo):
      // el equipo debe aprobar toda cuenta nueva.
      usuario = await User.create({
        nombre: name || 'Usuario Google',
        email,
        googleId,
        proveedorAuth: 'google',
        planActual: planElegido._id,
        cuentaVerificada: true,
        fotoPerfil: picture || undefined
      });

      esNueva = true;

      await crearSuscripcionParaPlan(usuario, planElegido, undefined);
      await notificarNuevaCuentaGoogle(usuario);
    }

    // 5) Suspendidas o inactivas no entran.
    await levantarSiVencio(usuario);

    if (estaBloqueada(usuario)) {
      return res.status(403).json(respuestaSuspension(usuario));
    }

    const token = jwt.sign(
      {
        id: usuario._id,
        rol: usuario.rol
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '7d'
      }
    );

    registrarActividad({
      usuarioId: usuario._id, nombre: usuario.nombre, email: usuario.email, rol: usuario.rol,
      categoria: 'cuenta', accion: esNueva ? 'registro_google' : 'inicio_sesion_google',
      descripcion: esNueva ? 'Se registró con Google' : 'Inició sesión con Google'
    });

    return res.status(esNueva ? 201 : 200).json({
      mensaje: 'Sesión iniciada con Google',
      token,
      usuario
    });

  } catch (error) {
    console.error('❌ Error en inicio de sesión con Google:', error);

    return res.status(500).json({
      mensaje: 'Error al iniciar sesión con Google. Inténtalo de nuevo.'
    });
  }
};


// ======================================================
// OBTENER PERFIL
// ======================================================

export const obtenerUsuario = async (req, res) => {
  try {
    const usuario = await User.findById(req.params.id);

    if (!usuario) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    return res.json(usuario);

  } catch (error) {
    console.error('❌ Error al obtener usuario:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// ACTUALIZAR USUARIO
// ======================================================

export const actualizarUsuario = async (req, res) => {
  try {
    const datosActualizar = {};

    // Nombre (2 a 60 caracteres)
    if (req.body.nombre !== undefined) {
      const nombre = String(req.body.nombre).trim();

      if (nombre.length < 2 || nombre.length > 60) {
        return res.status(400).json({
          mensaje: 'El nombre debe tener entre 2 y 60 caracteres'
        });
      }

      datosActualizar.nombre = nombre;
    }

    if (req.body.telefono !== undefined) {
      const telefono = String(req.body.telefono).trim();

      if (telefono && !/^[0-9+()\-\s]{7,20}$/.test(telefono)) {
        return res.status(400).json({
          mensaje: 'El teléfono no es válido'
        });
      }

      datosActualizar.telefono = telefono;
    }

    // Correo electrónico. Quien cambia SU PROPIO correo debe verificarlo primero con el
    // código que llega al correo nuevo (POST /:id/cambio-correo y /:id/cambio-correo/confirmar).
    // Solo un administrador puede cambiarlo directamente.
    if (req.body.email !== undefined) {
      const email = String(req.body.email).toLowerCase().trim();

      if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) {
        return res.status(400).json({
          mensaje: 'Correo electrónico inválido'
        });
      }

      const actual = await User.findById(req.params.id).select('email');

      if (actual && actual.email !== email) {
        if (req.usuario?.rol !== 'admin') {
          return res.status(400).json({
            mensaje: 'Para cambiar tu correo primero debes verificarlo con el código que te enviamos.',
            codigo: 'VERIFICACION_CORREO_REQUERIDA'
          });
        }

        const enUso = await User.findOne({
          email,
          _id: { $ne: req.params.id }
        }).select('_id');

        if (enUso) {
          return res.status(409).json({
            mensaje: 'Ese correo ya está registrado en otra cuenta'
          });
        }

        const revocado = await RevokedAccount.findOne({ email }).select('_id');

        if (revocado) {
          return res.status(403).json({
            mensaje: 'Ese correo no puede usarse en FitZone'
          });
        }

        datosActualizar.email = email;
      }
    }

    // Edad (entero de 10 a 120)
    if (req.body.edad !== undefined) {
      const edad = Number(req.body.edad);

      if (!Number.isInteger(edad) || edad < 10 || edad > 120) {
        return res.status(400).json({
          mensaje: 'La edad debe ser un número entero entre 10 y 120'
        });
      }

      datosActualizar.edad = edad;
    }

    // Género
    if (req.body.genero !== undefined) {
      const generosPermitidos = ['masculino', 'femenino', 'otro'];

      if (!generosPermitidos.includes(req.body.genero)) {
        return res.status(400).json({
          mensaje: 'Género no válido',
          generosPermitidos
        });
      }

      datosActualizar.genero = req.body.genero;
    }

    // Solo un administrador puede cambiar estos campos
    if (req.usuario?.rol === 'admin') {

      if (req.body.rol !== undefined) {
        datosActualizar.rol = req.body.rol;
      }

      if (req.body.estadoCuenta !== undefined) {
        datosActualizar.estadoCuenta = req.body.estadoCuenta;

        if (req.body.estadoCuenta !== 'suspendido') {
          datosActualizar.suspendidoHasta = null;
          datosActualizar.motivoSuspension = null;
        }
      }
    }

    const usuarioActual = await User.findById(req.params.id);

    if (!usuarioActual) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    // Actualizar foto de perfil
    if (req.file) {

      if (usuarioActual.fotoPerfilId) {
        await borrarImagenCloudinary(usuarioActual.fotoPerfilId);
      }

      datosActualizar.fotoPerfil = req.file.secure_url;
      datosActualizar.fotoPerfilId = req.file.public_id;
    }

    const usuario = await User.findByIdAndUpdate(
      req.params.id,
      datosActualizar,
      { new: true }
    );

    return res.json(usuario);

  } catch (error) {
    console.error('❌ Error al actualizar usuario:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// CAMBIO DE CORREO CON VERIFICACIÓN
// 1) El usuario escribe su correo nuevo → se envía un código de 6 dígitos a ESE correo.
// 2) Escribe el código → recién ahí el correo de la cuenta cambia.
// ======================================================

const SEGUNDOS_ENTRE_ENVIOS = 30;
const MAX_INTENTOS_CODIGO = 5;

export const solicitarCambioEmail = async (req, res) => {
  try {
    const nuevoEmail = String(req.body.email || '').toLowerCase().trim();
    const usuario = await User.findById(req.params.id);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    if (nuevoEmail === usuario.email) {
      return res.status(400).json({ mensaje: 'Ese ya es el correo de tu cuenta' });
    }

    const enUso = await User.findOne({ email: nuevoEmail, _id: { $ne: usuario._id } }).select('_id');
    if (enUso) {
      return res.status(409).json({ mensaje: 'Ese correo ya está registrado en otra cuenta' });
    }

    const revocado = await RevokedAccount.findOne({ email: nuevoEmail }).select('_id');
    if (revocado) {
      return res.status(403).json({ mensaje: 'Ese correo no puede usarse en FitZone' });
    }

    // Evita disparar correos sin parar
    const ultimoEnvio = usuario.codigoCambioEmailEnviado?.getTime() || 0;
    const espera = Math.ceil((ultimoEnvio + SEGUNDOS_ENTRE_ENVIOS * 1000 - Date.now()) / 1000);

    if (espera > 0 && usuario.emailPendiente === nuevoEmail) {
      return res.status(429).json({
        mensaje: `Espera ${espera} segundos para pedir otro código.`
      });
    }

    const codigo = crearCodigo();

    usuario.emailPendiente = nuevoEmail;
    usuario.codigoCambioEmail = hashCodigo(codigo);
    usuario.codigoCambioEmailExpira = vencimientoCodigo();
    usuario.codigoCambioEmailEnviado = new Date();
    usuario.intentosCambioEmail = 0;

    await usuario.save();

    if (process.env.NODE_ENV !== 'production') {
      console.log(`🔐 [DEV] Código para cambiar a ${nuevoEmail}: ${codigo}`);
    }

    const correo = correoCambioEmail({ nombre: usuario.nombre, codigo });

    const enviado = await enviarSinBloquear({
      from: process.env.EMAIL_USER,
      to: nuevoEmail,
      subject: correo.asunto,
      html: correo.html
    });

    if (!enviado) {
      return res.status(502).json({
        mensaje: 'No pudimos enviar el correo en este momento. Revisa que esté bien escrito e inténtalo de nuevo.',
        codigo: 'CORREO_NO_ENVIADO'
      });
    }

    return res.json({
      mensaje: 'Te enviamos un código al correo nuevo',
      emailPendiente: nuevoEmail,
      minutosCodigo: MINUTOS_CODIGO
    });

  } catch (error) {
    console.error('❌ Error al pedir el cambio de correo:', error);

    return res.status(500).json({
      mensaje: 'No se pudo iniciar el cambio de correo. Inténtalo de nuevo.'
    });
  }
};

export const confirmarCambioEmail = async (req, res) => {
  try {
    const { codigo } = req.body;
    const usuario = await User.findById(req.params.id);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    if (!usuario.emailPendiente || !usuario.codigoCambioEmail) {
      return res.status(400).json({
        mensaje: 'No hay un cambio de correo pendiente. Vuelve a pedir el código.',
        codigo: 'SIN_CAMBIO_PENDIENTE'
      });
    }

    const limpiar = () => {
      usuario.emailPendiente = undefined;
      usuario.codigoCambioEmail = undefined;
      usuario.codigoCambioEmailExpira = undefined;
      usuario.codigoCambioEmailEnviado = undefined;
      usuario.intentosCambioEmail = 0;
    };

    if (!usuario.codigoCambioEmailExpira || usuario.codigoCambioEmailExpira < Date.now()) {
      limpiar();
      await usuario.save();
      return res.status(400).json({
        mensaje: 'El código venció. Pide uno nuevo.',
        codigo: 'CODIGO_VENCIDO'
      });
    }

    if ((usuario.intentosCambioEmail || 0) >= MAX_INTENTOS_CODIGO) {
      limpiar();
      await usuario.save();
      return res.status(429).json({
        mensaje: 'Demasiados intentos. Pide un código nuevo.',
        codigo: 'DEMASIADOS_INTENTOS'
      });
    }

    if (hashCodigo(codigo) !== usuario.codigoCambioEmail) {
      usuario.intentosCambioEmail = (usuario.intentosCambioEmail || 0) + 1;
      await usuario.save();
      return res.status(400).json({ mensaje: 'Código incorrecto. Revísalo e inténtalo de nuevo.' });
    }

    // Alguien pudo registrar ese correo mientras tanto
    const enUso = await User.findOne({ email: usuario.emailPendiente, _id: { $ne: usuario._id } }).select('_id');
    if (enUso) {
      limpiar();
      await usuario.save();
      return res.status(409).json({ mensaje: 'Ese correo ya fue registrado por otra cuenta' });
    }

    const emailAnterior = usuario.email;

    usuario.email = usuario.emailPendiente;
    usuario.cuentaVerificada = true;
    limpiar();

    await usuario.save();

    // Aviso de seguridad al correo anterior (no bloquea la respuesta)
    if (emailAnterior && emailAnterior !== usuario.email) {
      const aviso = correoEmailCambiado({ nombre: usuario.nombre, emailNuevo: usuario.email });
      enviarCorreoSeguro({
        from: process.env.EMAIL_USER,
        to: emailAnterior,
        subject: aviso.asunto,
        html: aviso.html
      });
    }

    return res.json(usuario);

  } catch (error) {
    console.error('❌ Error al confirmar el cambio de correo:', error);

    return res.status(500).json({
      mensaje: 'No se pudo confirmar el correo. Inténtalo de nuevo.'
    });
  }
};


// ======================================================
// CAMBIAR / CREAR CONTRASEÑA (con validación y confirmación)
// ======================================================

const validarPasswordNueva = (password) => {
  if (typeof password !== 'string' || password.length < 8) {
    return 'La contraseña debe tener al menos 8 caracteres';
  }
  if (password.length > 72) {
    return 'La contraseña no puede superar 72 caracteres';
  }
  if (!/[a-z]/.test(password) || !/[A-Z]/.test(password) || !/[0-9]/.test(password)) {
    return 'La contraseña debe incluir mayúscula, minúscula y número';
  }
  return null;
};

export const cambiarPassword = async (req, res) => {
  try {
    const { passwordActual, passwordNueva, confirmacion } = req.body || {};

    const usuario = await User.findById(req.params.id);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    const errorFormato = validarPasswordNueva(passwordNueva);

    if (errorFormato) {
      return res.status(400).json({ mensaje: errorFormato });
    }

    if (passwordNueva !== confirmacion) {
      return res.status(400).json({
        mensaje: 'La confirmación no coincide con la contraseña nueva'
      });
    }

    // Si ya tiene contraseña, debe demostrar que conoce la actual
    if (usuario.passwordHash) {
      if (!passwordActual) {
        return res.status(400).json({ mensaje: 'Escribe tu contraseña actual' });
      }

      const coincide = await bcrypt.compare(String(passwordActual), usuario.passwordHash);

      if (!coincide) {
        return res.status(400).json({ mensaje: 'La contraseña actual no es correcta' });
      }

      if (await bcrypt.compare(passwordNueva, usuario.passwordHash)) {
        return res.status(400).json({
          mensaje: 'La contraseña nueva debe ser distinta a la actual'
        });
      }
    }

    usuario.passwordHash = await bcrypt.hash(passwordNueva, 10);
    usuario.resetPasswordToken = undefined;
    usuario.resetPasswordExpira = undefined;
    await usuario.save();

    return res.json({ mensaje: 'Contraseña actualizada correctamente' });

  } catch (error) {
    console.error('❌ Error al cambiar la contraseña:', error);
    return res.status(500).json({ mensaje: 'No se pudo cambiar la contraseña' });
  }
};


// ======================================================
// ELIMINAR MI CUENTA
// DELETE /api/users/:id   (solo la propia persona)
//
// Cuentas con contraseña: se pide la contraseña en el body ({ password }).
// Cuentas de Google (sin contraseña local): la app pide escribir "ELIMINAR".
// ======================================================

export const eliminarMiCuenta = async (req, res) => {
  try {
    const { id } = req.params;

    // Ni siquiera un admin puede usar esta ruta para borrar la cuenta de otra persona
    if (!mongoose.isValidObjectId(id) || String(req.usuario.id) !== String(id)) {
      return res.status(403).json({ mensaje: 'Solo puedes eliminar tu propia cuenta' });
    }

    const usuario = await User.findById(id);

    if (!usuario) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }

    if (usuario.rol === 'admin') {
      return res.status(400).json({
        mensaje: 'Una cuenta de administrador no se puede eliminar desde la app'
      });
    }

    // Cuentas con contraseña local: debe demostrar que es la persona dueña
    if (usuario.passwordHash && usuario.proveedorAuth !== 'google') {
      const { password } = req.body || {};

      if (!password) {
        return res.status(400).json({
          mensaje: 'Escribe tu contraseña para confirmar',
          codigo: 'PASSWORD_REQUERIDA'
        });
      }

      const coincide = await bcrypt.compare(String(password), usuario.passwordHash);

      if (!coincide) {
        return res.status(400).json({ mensaje: 'La contraseña no es correcta' });
      }
    }

    await eliminarCuentaYDatos(usuario);

    return res.json({ mensaje: 'Tu cuenta fue eliminada' });

  } catch (error) {
    console.error('❌ Error al eliminar la cuenta:', error);
    return res.status(500).json({ mensaje: 'No se pudo eliminar la cuenta. Inténtalo de nuevo.' });
  }
};


// ======================================================
// CAMBIAR ROL DE USUARIO
// SOLO ADMIN
// ======================================================

export const cambiarRolUsuario = async (req, res) => {
  try {
    const { email, rol } = req.body;

    if (!email || !rol) {
      return res.status(400).json({
        mensaje: 'El email y el rol son obligatorios'
      });
    }

    const rolesPermitidos = ['cliente', 'entrenador', 'admin'];

    if (!rolesPermitidos.includes(rol)) {
      return res.status(400).json({
        mensaje: 'Rol no válido',
        rolesPermitidos
      });
    }

    const usuario = await buscarPorEmail(email);

    if (!usuario) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    usuario.rol = rol;

    await usuario.save();

    return res.status(200).json({
      mensaje: 'Rol actualizado correctamente',
      usuario: {
        id: usuario._id,
        nombre: usuario.nombre,
        email: usuario.email,
        rol: usuario.rol
      }
    });

  } catch (error) {
    console.error('❌ Error al cambiar rol:', error);

    return res.status(500).json({
      mensaje: 'Error al cambiar el rol del usuario',
      error: error.message
    });
  }
};


// ======================================================
// SOLICITAR RECUPERACIÓN DE CONTRASEÑA
// ======================================================

export const solicitarRecuperacion = async (req, res) => {
  try {
    const { email } = req.body;

    // La respuesta es igual exista o no el correo:
    // así nadie puede averiguar qué correos están registrados.
    const respuesta = {
      mensaje:
        'Si el correo está registrado, te enviamos un código para restablecer tu contraseña'
    };

    const usuario = await buscarPorEmail(email);

    if (!usuario) {
      return res.json(respuesta);
    }

    const codigo = crearCodigo();

    usuario.resetPasswordToken = hashCodigo(codigo);
    usuario.resetPasswordExpira = vencimientoCodigo();

    await usuario.save();

    if (process.env.NODE_ENV !== 'production') {
      console.log(`🔐 [DEV] Código para restablecer la contraseña de ${usuario.email}: ${codigo}`);
    }

    const correo = correoRecuperacion({ nombre: usuario.nombre, codigo });

    await enviarSinBloquear({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: correo.asunto,
      html: correo.html
    });

    return res.json(respuesta);

  } catch (error) {
    console.error('❌ Error en recuperación de contraseña:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// RESTABLECER CONTRASEÑA CON CÓDIGO
// ======================================================

export const restablecerConCodigo = async (req, res) => {
  try {
    const { email, codigo, password } = req.body;

    const candidato = await buscarPorEmail(email);

    const usuario =
      candidato &&
      candidato.resetPasswordToken === hashCodigo(codigo) &&
      candidato.resetPasswordExpira &&
      candidato.resetPasswordExpira > Date.now()
        ? candidato
        : null;

    if (!usuario) {
      return res.status(400).json({
        mensaje: 'Código inválido o expirado'
      });
    }

    usuario.passwordHash = await bcrypt.hash(password, 10);

    usuario.resetPasswordToken = undefined;
    usuario.resetPasswordExpira = undefined;

    // Si recibió el código en su correo, el correo es suyo
    usuario.cuentaVerificada = true;
    usuario.codigoVerificacion = undefined;
    usuario.codigoVerificacionExpira = undefined;

    await usuario.save();

    return res.json({
      mensaje: 'Contraseña actualizada correctamente'
    });

  } catch (error) {
    console.error('❌ Error al restablecer contraseña con código:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};


// ======================================================
// RESTABLECER CONTRASEÑA
// ======================================================

export const restablecerPassword = async (req, res) => {
  try {
    const { token } = req.params;
    const { password } = req.body;

    const usuario = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpira: {
        $gt: Date.now()
      }
    });

    if (!usuario) {
      return res.status(400).json({
        mensaje: 'Token inválido o expirado'
      });
    }

    usuario.passwordHash = await bcrypt.hash(password, 10);

    usuario.resetPasswordToken = undefined;
    usuario.resetPasswordExpira = undefined;

    await usuario.save();

    return res.json({
      mensaje: 'Contraseña actualizada correctamente'
    });

  } catch (error) {
    console.error('❌ Error al restablecer contraseña:', error);

    return res.status(500).json({
      error: error.message
    });
  }
};