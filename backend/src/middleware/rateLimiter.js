import rateLimit from 'express-rate-limit';

export const limitarLogin = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { mensaje: 'Demasiados intentos de inicio de sesión. Intenta de nuevo en 15 minutos.' },
  standardHeaders: true,
  legacyHeaders: false
});

export const limitarRegistro = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: { mensaje: 'Demasiados registros desde esta IP. Intenta más tarde.' },
  standardHeaders: true,
  legacyHeaders: false
});

export const limitarRecuperacion = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 3,
  message: { mensaje: 'Demasiadas solicitudes de recuperación. Intenta más tarde.' },
  standardHeaders: true,
  legacyHeaders: false
});