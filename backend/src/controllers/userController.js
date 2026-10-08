import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { OAuth2Client } from 'google-auth-library';

import User from '../models/User.js';
import Plan from '../models/Plan.js';
import transporter from '../utils/mailer.js';
import { crearSuscripcionParaPlan } from '../helpers/suscripciones.js';
import { borrarImagenCloudinary } from '../utils/cloudinary.js';

const googleClient = new OAuth2Client();


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

    const codigoVerificacion = Math.floor(
      100000 + Math.random() * 900000
    ).toString();

    const nuevoUsuario = await User.create({
      nombre,
      email,
      passwordHash,
      telefono,
      planActual: plan._id,
      cuentaVerificada: false,
      codigoVerificacion,
      codigoVerificacionExpira: Date.now() + 15 * 60 * 1000
    });

    await crearSuscripcionParaPlan(
      nuevoUsuario,
      plan,
      metodoPago
    );

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: nuevoUsuario.email,
      subject: 'Verifica tu cuenta - FitZone',
      html: `
        <p>Hola ${nuevoUsuario.nombre},</p>

        <p>
          Tu código de verificación es:
          <strong>${codigoVerificacion}</strong>
        </p>

        <p>Este código vence en 15 minutos.</p>

        <p>Gracias por registrarte en FitZone.</p>
      `
    });

    return res.status(201).json({
      mensaje: plan.esGratuito
        ? 'Usuario registrado con plan gratuito. Revisa tu correo para verificar tu cuenta.'
        : 'Usuario registrado. Tu plan está pendiente de aprobación. Revisa tu correo para verificar tu cuenta.',
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

    if (
      usuario.codigoVerificacion !== codigo ||
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

    const codigoVerificacion = Math.floor(
      100000 + Math.random() * 900000
    ).toString();

    usuario.codigoVerificacion = codigoVerificacion;

    usuario.codigoVerificacionExpira =
      Date.now() + 15 * 60 * 1000;

    await usuario.save();

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: 'Nuevo código de verificación - FitZone',
      html: `
        <p>Hola ${usuario.nombre},</p>

        <p>
          Tu nuevo código de verificación es:
          <strong>${codigoVerificacion}</strong>
        </p>

        <p>Este código vence en 15 minutos.</p>

        <p>Gracias por usar FitZone.</p>
      `
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
        mensaje: 'Debes verificar tu cuenta antes de iniciar sesión'
      });
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
    const camposPermitidos = [
      'nombre',
      'telefono'
    ];

    const datosActualizar = {};

    for (const campo of camposPermitidos) {
      if (req.body[campo] !== undefined) {
        datosActualizar[campo] = req.body[campo];
      }
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


// Solicitar recuperación de contraseña (envía un código de 6 dígitos)
export const solicitarRecuperacion = async (req, res) => {
  try {
    const { email } = req.body;
    const usuario = await User.findOne({ email });
    if (!usuario) return res.status(404).json({ mensaje: 'No existe una cuenta con ese correo' });

    const codigo = crypto.randomInt(100000, 1000000).toString();
    usuario.resetPasswordToken = codigo;
    usuario.resetPasswordExpira = Date.now() + 15 * 60 * 1000; // 15 minutos
    await usuario.save();

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: 'Código para recuperar tu contraseña - FitZone',
      html: `<p>Hola ${usuario.nombre},</p>
             <p>Tu código para recuperar tu contraseña es:</p>
             <h2 style="letter-spacing: 6px;">${codigo}</h2>
             <p>Este código vence en 15 minutos. Si no lo solicitaste, ignora este correo.</p>`
    });

    res.json({ mensaje: 'Te enviamos un código a tu correo' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Restablecer contraseña con el código recibido por correo
export const restablecerPassword = async (req, res) => {
  try {
    const { email, codigo, password } = req.body;

    const usuario = await User.findOne({
      email,
      resetPasswordToken: codigo,
      resetPasswordExpira: { $gt: Date.now() }
    });

    if (!usuario) return res.status(400).json({ mensaje: 'Código inválido o expirado' });

    usuario.passwordHash = await bcrypt.hash(password, 10);
    usuario.resetPasswordToken = undefined;
    usuario.resetPasswordExpira = undefined;
    await usuario.save();

    res.json({ mensaje: 'Contraseña actualizada correctamente' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};