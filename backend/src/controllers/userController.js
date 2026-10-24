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
import {MINUTOS_CODIGO, correoVerificacion, correoRecuperacion, escapeHtml} from '../utils/emailTemplates.js';
import RevokedAccount from '../models/RevokedAccount.js';

const googleClient = new OAuth2Client();

// Códigos de 6 dígitos (criptográficamente aleatorios) que vencen en 15 minutos
const crearCodigo = () => crypto.randomInt(100000, 1000000).toString();
const MSG_REVOCADA =
  'Tu cuenta fue revocada por el equipo de FitZone. Si crees que es un error, escríbenos por los canales oficiales.';
const vencimientoCodigo = () => Date.now() + MINUTOS_CODIGO * 60 * 1000;


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

    const revocada = await RevokedAccount.findOne({ email: String(email).toLowerCase().trim() });
    if (revocada) {
      return res.status(403).json({ mensaje: MSG_REVOCADA, codigo: 'CUENTA_REVOCADA' });
    }

    const existe = await User.findOne({ email });
    if (existe) {
      return res.status(400).json({
        mensaje: 'El correo ya está registrado'
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const plan = planId
      ? await Plan.findById(planId)
      : await Plan.findOne({ esGratuito: true });

    if (!plan) {
      return res.status(404).json({
        mensaje: 'Plan no encontrado'
      });
    }

    const codigoVerificacion = crearCodigo();

    const nuevoUsuario = await User.create({
      nombre,
      email,
      passwordHash,
      telefono,
      planActual: plan._id,
      cuentaVerificada: false,
      estadoCuenta: 'pendiente', // el equipo debe aprobar la cuenta
      codigoVerificacion: hashCodigo(codigoVerificacion),
      codigoVerificacionExpira: vencimientoCodigo()
    });

    await crearSuscripcionParaPlan(
      nuevoUsuario,
      plan,
      metodoPago
    );

    if (process.env.NODE_ENV !== 'production') {
      console.log(`🔐 [DEV] Código de verificación de ${nuevoUsuario.email}: ${codigoVerificacion}`);
    }

    const correo = correoVerificacion({
      nombre: nuevoUsuario.nombre,
      codigo: codigoVerificacion
    });

    await enviarCorreoSeguro({
      from: process.env.EMAIL_USER,
      to: nuevoUsuario.email,
      subject: correo.asunto,
      html: correo.html
    });

    return res.status(201).json({
      mensaje: 'Cuenta creada. Revisa tu correo para verificarla; después el equipo de FitZone aprobará tu cuenta.',
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

    const usuario = await User.findOne({ email });

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

    const usuario = await User.findOne({ email });

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

    await enviarCorreoSeguro({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: correo.asunto,
      html: correo.html
    });

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
// LOGIN
// ======================================================

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

export const iniciarSesion = async (req, res) => {
  try {
    const { email, password, planId } = req.body;

    const usuario = await User.findOne({ email });

    if (!usuario) {
      const revocada = await RevokedAccount.findOne({ email: String(email).toLowerCase().trim() });

      if (revocada) {
        return res.status(403).json({
          mensaje: MSG_REVOCADA,
          codigo: 'CUENTA_REVOCADA',
          motivo: revocada.motivo || undefined
        });
      }

      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    if (!usuario.passwordHash) {
      return res.status(400).json({
        mensaje: 'Esta cuenta utiliza inicio de sesión con Google'
      });
    }

    const passwordValido = await bcrypt.compare(
      password,
      usuario.passwordHash
    );

    if (!passwordValido) {
      return res.status(401).json({
        mensaje: 'Contraseña incorrecta'
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
    if (['inactivo', 'suspendido'].includes(usuario.estadoCuenta)) {
      return res.status(403).json({
        mensaje: 'Tu cuenta está suspendida. Contacta al equipo de FitZone.',
        codigo: 'CUENTA_SUSPENDIDA'
      });
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
    //    Solo aquí un fallo significa "token inválido" (401).
    let payload;

    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: audiencias
      });

      payload = ticket.getPayload();
    } catch (error) {
      // El motivo exacto (audiencia distinta, token vencido...) queda en el log del servidor
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
    let usuario = await User.findOne({
      $or: [{ googleId }, { email }]
    });

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

    // 5) Suspendidas o inactivas no entran. Las pendientes o rechazadas sí
    //    reciben sesión para ver su estado (authMiddleware bloquea el resto).
    if (['inactivo', 'suspendido'].includes(usuario.estadoCuenta)) {
      return res.status(403).json({
        mensaje: 'Tu cuenta está suspendida. Contacta al equipo de FitZone.',
        codigo: 'CUENTA_SUSPENDIDA'
      });
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

    // Correo electrónico (único y con formato válido)
    if (req.body.email !== undefined) {
      const email = String(req.body.email).toLowerCase().trim();

      if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) {
        return res.status(400).json({
          mensaje: 'Correo electrónico inválido'
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
        datosActualizar.estadoCuenta =
          req.body.estadoCuenta;
      }
    }

    const usuarioActual = await User.findById(
      req.params.id
    );

    if (!usuarioActual) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    // Actualizar foto de perfil
    if (req.file) {

      if (usuarioActual.fotoPerfilId) {
        await borrarImagenCloudinary(
          usuarioActual.fotoPerfilId
        );
      }

      datosActualizar.fotoPerfil =
        req.file.secure_url;

      datosActualizar.fotoPerfilId =
        req.file.public_id;
    }

    const usuario = await User.findByIdAndUpdate(
      req.params.id,
      datosActualizar,
      {
        new: true
      }
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

    const rolesPermitidos = [
      'cliente',
      'entrenador',
      'admin'
    ];

    if (!rolesPermitidos.includes(rol)) {
      return res.status(400).json({
        mensaje: 'Rol no válido',
        rolesPermitidos
      });
    }

    const usuario = await User.findOne({ email });

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
    console.error(
      '❌ Error al cambiar rol:',
      error
    );

    return res.status(500).json({
      mensaje: 'Error al cambiar el rol del usuario',
      error: error.message
    });
  }
};


// ======================================================
// SOLICITAR RECUPERACIÓN DE CONTRASEÑA
// ======================================================

// Código de recuperación: se guarda solo su hash (SHA-256)
const hashCodigo = (codigo) =>
  crypto.createHash('sha256').update(String(codigo)).digest('hex');

export const solicitarRecuperacion = async (req, res) => {
  try {
    const { email } = req.body;

    // La respuesta es igual exista o no el correo:
    // así nadie puede averiguar qué correos están registrados.
    const respuesta = {
      mensaje:
        'Si el correo está registrado, te enviamos un código para restablecer tu contraseña'
    };

    const usuario = await User.findOne({ email });

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

    await enviarCorreoSeguro({
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

    const usuario = await User.findOne({
      email,
      resetPasswordToken: hashCodigo(codigo),
      resetPasswordExpira: { $gt: Date.now() }
    });

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

    usuario.passwordHash =
      await bcrypt.hash(password, 10);

    usuario.resetPasswordToken = undefined;
    usuario.resetPasswordExpira = undefined;

    await usuario.save();

    return res.json({
      mensaje:
        'Contraseña actualizada correctamente'
    });

  } catch (error) {
    console.error(
      '❌ Error al restablecer contraseña:',
      error
    );

    return res.status(500).json({
      error: error.message
    });
  }
};