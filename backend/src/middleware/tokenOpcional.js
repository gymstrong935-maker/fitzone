import jwt from 'jsonwebtoken';

const tokenOpcional = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader) {
    const token = authHeader.split(' ')[1];
    try {
      req.usuario = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      // Token inválido o expirado: continúa como usuario anónimo, sin bloquear
      req.usuario = null;
    }
  } else {
    req.usuario = null;
  }
  next();
};

export default tokenOpcional;