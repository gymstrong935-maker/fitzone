import jwt from 'jsonwebtoken';
import User from '../models/User.js';

const ESTADOS_BLOQUEADOS = ['inactivo', 'suspendido'];

// Lo único que puede hacer una cuenta que aún está en revisión:
// consultar su propio usuario (para saber si ya la aprobaron) y escribir a soporte.
const permitidoEnRevision = (req) => {
  const ruta = req.originalUrl.split('?')[0];
  if (req.method === 'GET' && /^\/api\/users\/[a-fA-F0-9]{24}\/?$/.test(ruta)) return true;
  return ruta.startsWith('/api/support');
};

// ======================================================
// VERIFICAR TOKEN JWT + ESTADO DE LA CUENTA
// ======================================================

export const verificarToken = async (req, res, next) => {
  let decoded;

  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({ mensaje: 'Token no proporcionado' });
    }

    const partes = authHeader.split(' ');

    if (partes.length !== 2 || partes[0] !== 'Bearer' || !partes[1]) {
      return res.status(401).json({
        mensaje: 'Formato de autorización inválido. Usa Bearer <token>'
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error('❌ JWT_SECRET no está configurado en .env');
      return res.status(500).json({ mensaje: 'JWT_SECRET no está configurado en el servidor' });
    }

    decoded = jwt.verify(partes[1], process.env.JWT_SECRET);
  } catch (error) {
    console.error('❌ Error verificando JWT:', error.message);
    return res.status(403).json({ mensaje: 'Token inválido o expirado' });
  }

  try {
    // El estado actual de la cuenta manda sobre lo que diga el token
    const cuenta = await User.findById(decoded.id).select('estadoCuenta rol');

    if (!cuenta) {
      return res.status(403).json({
        mensaje: 'Tu cuenta fue revocada por el equipo de FitZone.',
        codigo: 'CUENTA_REVOCADA'
      });
    }

    decoded.rol = cuenta.rol; // el rol vigente (por si lo cambiaron)

    if (cuenta.rol !== 'admin') {
      const estado = cuenta.estadoCuenta;

      if (ESTADOS_BLOQUEADOS.includes(estado)) {
        return res.status(403).json({
          mensaje: 'Tu cuenta está suspendida. Contacta al equipo de FitZone.',
          codigo: 'CUENTA_SUSPENDIDA'
        });
      }

      if (estado === 'pendiente' && !permitidoEnRevision(req)) {
        return res.status(403).json({
          mensaje: 'Tu cuenta está pendiente de aprobación.',
          codigo: 'CUENTA_PENDIENTE'
        });
      }

      if (estado === 'rechazado' && !permitidoEnRevision(req)) {
        return res.status(403).json({
          mensaje: 'Tu solicitud de registro no fue aprobada.',
          codigo: 'CUENTA_RECHAZADA'
        });
      }
    }

    req.usuario = decoded;
    next();
  } catch (error) {
    console.error('❌ Error comprobando la cuenta:', error.message);
    return res.status(500).json({ mensaje: 'No se pudo comprobar tu cuenta. Inténtalo de nuevo.' });
  }
};


// ======================================================
// VERIFICAR ADMIN
// ======================================================

export const verificarAdmin = (req, res, next) => {
  if (req.usuario?.rol !== 'admin') {
    return res.status(403).json({
      mensaje: 'Acción reservada para administradores'
    });
  }

  next();
};


// ======================================================
// VERIFICAR DUEÑO
// ======================================================

export const verificarDueño = (req, res, next) => {
  const idEnRuta =
    req.params.usuarioId ||
    req.params.id;

  if (
    req.usuario?.rol !== 'admin' &&
    req.usuario?.id !== idEnRuta
  ) {
    return res.status(403).json({
      mensaje: 'No tienes permiso para acceder a estos datos'
    });
  }

  next();
};


// ======================================================
// FORZAR EL usuarioId DEL TOKEN EN EL BODY
// Evita que un usuario cree datos a nombre de otro.
// Un admin sí puede indicar otro usuarioId.
// Debe ir DESPUÉS de verificarToken y ANTES de validar(...).
// ======================================================

export const usuarioDelToken = (req, res, next) => {
  const esAdmin = req.usuario?.rol === 'admin';
  const body = req.body && typeof req.body === 'object' ? req.body : {};

  if (!esAdmin || !body.usuarioId) {
    req.body = { ...body, usuarioId: req.usuario.id };
  }

  next();
};


// ======================================================
// EXPORTACIÓN POR DEFECTO
// ======================================================

export default verificarToken;