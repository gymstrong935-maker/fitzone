import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { OAuth2Client } from 'google-auth-library';

import User from '../models/User.js';
import Plan from '../models/Plan.js';
import transporter from '../utils/mailer.js';
import { crearSuscripcionParaPlan } from '../helpers/suscripciones.js';
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

export const iniciarSesion = async (req, res) => {
  try {
    const { email, password } = req.body;

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

export const iniciarSesionGoogle = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        mensaje: 'El ID token de Google es obligatorio'
      });
    }

    const webClientId =
      process.env.GOOGLE_SERVER_CLIENT_ID;

    if (!webClientId) {
      console.error(
        '❌ GOOGLE_SERVER_CLIENT_ID no está configurado'
      );

      return res.status(500).json({
        mensaje: 'La configuración de Google no está disponible'
      });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: webClientId
    });

    const payload = ticket.getPayload();

    if (!payload) {
      return res.status(401).json({
        mensaje: 'Token de Google inválido'
      });
    }

    const {
      sub: googleId,
      email,
      name,
      picture,
      email_verified: emailVerificado
    } = payload;

    if (!email || !googleId) {
      return res.status(401).json({
        mensaje: 'Google no proporcionó los datos necesarios'
      });
    }

    if (!emailVerificado) {
      return res.status(403).json({
        mensaje: 'El correo de Google no está verificado'
      });
    }

    let usuario = await User.findOne({
      $or: [
        { googleId },
        { email }
      ]
    });

    if (usuario) {

      if (
        usuario.googleId &&
        usuario.googleId !== googleId
      ) {
        return res.status(409).json({
          mensaje:
            'El correo está asociado a otra cuenta de Google'
        });
      }

      if (!usuario.googleId) {
        usuario.googleId = googleId;
        usuario.proveedorAuth = 'google';

        if (!usuario.fotoPerfil && picture) {
          usuario.fotoPerfil = picture;
        }

        await usuario.save();
      }

    } else {

      const plan = await Plan.findOne({
        esGratuito: true
      });

      if (!plan) {
        return res.status(404).json({
          mensaje:
            'No existe un plan gratuito disponible para registrar la cuenta'
        });
      }

      usuario = await User.create({
        nombre: name || 'Usuario Google',
        email,
        googleId,
        proveedorAuth: 'google',
        planActual: plan._id,
        cuentaVerificada: true,
        fotoPerfil: picture || undefined
      });

      await crearSuscripcionParaPlan(
        usuario,
        plan,
        undefined
      );
    }

    if (usuario.estadoCuenta !== 'activo') {
      return res.status(403).json({
        mensaje: 'La cuenta no está activa'
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

    return res.json({
      mensaje: 'Sesión iniciada con Google',
      token,
      usuario
    });

  } catch (error) {
    console.error(
      '❌ Error en inicio de sesión con Google:',
      error
    );

    return res.status(401).json({
      mensaje: 'No se pudo validar la cuenta de Google'
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
      datosActualizar.telefono = req.body.telefono;
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