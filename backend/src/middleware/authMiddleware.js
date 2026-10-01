import jwt from 'jsonwebtoken';

// ======================================================
// VERIFICAR TOKEN JWT
// ======================================================

export const verificarToken = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        mensaje: 'Token no proporcionado'
      });
    }

    const partes = authHeader.split(' ');

    if (
      partes.length !== 2 ||
      partes[0] !== 'Bearer' ||
      !partes[1]
    ) {
      return res.status(401).json({
        mensaje: 'Formato de autorización inválido. Usa Bearer <token>'
      });
    }

    const token = partes[1];

    if (!process.env.JWT_SECRET) {
      console.error('❌ JWT_SECRET no está configurado en .env');

      return res.status(500).json({
        mensaje: 'JWT_SECRET no está configurado en el servidor'
      });
    }

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    req.usuario = decoded;

    next();

  } catch (error) {
    console.error('❌ Error verificando JWT:', error.message);

    return res.status(403).json({
      mensaje: 'Token inválido o expirado'
    });
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
// EXPORTACIÓN POR DEFECTO
// ======================================================

export default verificarToken;