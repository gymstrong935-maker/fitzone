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

// Registro
export const registrarUsuario = async (req, res) => {
  try {
    const { nombre, email, password, telefono, planId, metodoPago } = req.body;

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
      `
    });

    res.status(201).json({
      mensaje: plan.esGratuito
        ? 'Usuario registrado con plan gratuito. Revisa tu correo para verificar tu cuenta.'
        : 'Usuario registrado. Tu plan está pendiente de aprobación. Revisa tu correo para verificar tu cuenta.',
      usuario: nuevoUsuario
    });

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};


// Verificar cuenta con el código enviado por correo
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

    res.json({
      mensaje: 'Cuenta verificada correctamente'
    });

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};


// Reenviar código de verificación
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
      `
    });

    res.json({
      mensaje: 'Código reenviado correctamente'
    });

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};


// Inicio de sesión
export const iniciarSesion = async (req, res) => {
  try {
    const { email, password } = req.body;

    const usuario = await User.findOne({ email });

    if (!usuario) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    // Las cuentas creadas exclusivamente con Google
    // no tienen contraseña local.
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

    res.json({
      mensaje: 'Sesión iniciada',
      token,
      usuario
    });

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};


// Inicio de sesión / registro con Google
export const iniciarSesionGoogle = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        mensaje: 'El ID token de Google es obligatorio'
      });
    }

    const webClientId = process.env.GOOGLE_SERVER_CLIENT_ID;

    if (!webClientId) {
      console.error(
        '❌ GOOGLE_SERVER_CLIENT_ID no está configurado'
      );

      return res.status(500).json({
        mensaje: 'La configuración de Google no está disponible'
      });
    }

    // Verificar el token recibido desde Flutter
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

    // Buscar primero por Google ID o por correo
    let usuario = await User.findOne({
      $or: [
        { googleId },
        { email }
      ]
    });

    if (usuario) {

      // Si el correo ya pertenece a otro Google ID
      if (
        usuario.googleId &&
        usuario.googleId !== googleId
      ) {
        return res.status(409).json({
          mensaje: 'El correo está asociado a otra cuenta de Google'
        });
      }

      // Vincular una cuenta existente con Google
      if (!usuario.googleId) {
        usuario.googleId = googleId;
        usuario.proveedorAuth = 'google';

        if (!usuario.fotoPerfil && picture) {
          usuario.fotoPerfil = picture;
        }

        await usuario.save();
      }

    } else {

      // Buscar el plan gratuito para nuevos usuarios Google
      const plan = await Plan.findOne({
        esGratuito: true
      });

      if (!plan) {
        return res.status(404).json({
          mensaje:
            'No existe un plan gratuito disponible para registrar la cuenta'
        });
      }

      // Crear nuevo usuario mediante Google
      usuario = await User.create({
        nombre: name || 'Usuario Google',
        email,
        googleId,
        proveedorAuth: 'google',
        planActual: plan._id,
        cuentaVerificada: true,
        fotoPerfil: picture || undefined
      });

      // Crear la suscripción correspondiente
      await crearSuscripcionParaPlan(
        usuario,
        plan,
        undefined
      );
    }

    // Verificar que la cuenta esté activa
    if (usuario.estadoCuenta !== 'activo') {
      return res.status(403).json({
        mensaje: 'La cuenta no está activa'
      });
    }

    // Crear JWT propio de FitZone
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


// Obtener perfil
export const obtenerUsuario = async (req, res) => {
  try {
    const usuario = await User.findById(req.params.id);

    if (!usuario) {
      return res.status(404).json({
        mensaje: 'Usuario no encontrado'
      });
    }

    res.json(usuario);

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};


// Actualizar usuario
// Lista blanca de campos editables + foto de perfil opcional
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

    res.json(usuario);

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};


// Solicitar recuperación de contraseña
export const solicitarRecuperacion = async (req, res) => {
  try {
    const { email } = req.body;

    const usuario = await User.findOne({ email });

    if (!usuario) {
      return res.status(404).json({
        mensaje: 'No existe una cuenta con ese correo'
      });
    }

    const token = crypto
      .randomBytes(32)
      .toString('hex');

    usuario.resetPasswordToken = token;

    usuario.resetPasswordExpira =
      Date.now() + 3600000;

    await usuario.save();

    const enlace =
      `http://localhost:4000/api/users/reset-password/${token}`;

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: usuario.email,
      subject: 'Recuperación de contraseña - FitZone',
      html: `
        <p>Hola ${usuario.nombre},</p>
        <p>
          Solicitaste recuperar tu contraseña.
          Este enlace vence en 1 hora:
        </p>
        <a href="${enlace}">
          ${enlace}
        </a>
      `
    });

    res.json({
      mensaje: 'Se envió un correo con las instrucciones'
    });

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};


// Restablecer contraseña
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

    res.json({
      mensaje: 'Contraseña actualizada correctamente'
    });

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
};