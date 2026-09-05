import jwt from 'jsonwebtoken';

export const verificarToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ mensaje: 'Token no proporcionado' });

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.usuario = decoded;
    next();
  } catch (error) {
    res.status(403).json({ mensaje: 'Token inválido o expirado' });
  }
};

// Solo permite continuar si el usuario autenticado tiene rol admin
export const verificarAdmin = (req, res, next) => {
  if (req.usuario?.rol !== 'admin') {
    return res.status(403).json({ mensaje: 'Acción reservada para administradores' });
  }
  next();
};

// Solo permite continuar si el :usuarioId de la URL coincide con el usuario del token
// (o si es admin, que puede ver/modificar cualquier usuario)
export const verificarDueño = (req, res, next) => {
  const idEnRuta = req.params.usuarioId || req.params.id;
  if (req.usuario?.rol !== 'admin' && req.usuario?.id !== idEnRuta) {
    return res.status(403).json({ mensaje: 'No tienes permiso para acceder a estos datos' });
  }
  next();
};
export default verificarToken;