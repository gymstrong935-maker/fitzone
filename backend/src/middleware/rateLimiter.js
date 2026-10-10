import rateLimit from 'express-rate-limit';

const esProduccion = process.env.NODE_ENV === 'production';

// En desarrollo los límites son amplios para poder probar sin bloquearte.
const limite = (produccion, desarrollo) => (esProduccion ? produccion : desarrollo);

export const limitarLogin = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: limite(5, 100),
  message: { mensaje: 'Demasiados intentos de inicio de sesión. Intenta de nuevo en 15 minutos.' },
  standardHeaders: true,
  legacyHeaders: false
});

export const limitarRegistro = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: limite(5, 100),
  message: { mensaje: 'Demasiados registros desde esta IP. Intenta más tarde.' },
  standardHeaders: true,
  legacyHeaders: false
});

export const limitarChat = rateLimit({
  windowMs: 60 * 1000, // 1 minuto
  max: limite(10, 100), // máximo 10 mensajes por minuto en producción
  message: { mensaje: 'Estás enviando mensajes muy rápido. Espera un momento.' },
  standardHeaders: true,
  legacyHeaders: false
});

export const limitarRecuperacion = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: limite(3, 100),
  message: { mensaje: 'Demasiadas solicitudes de recuperación. Intenta más tarde.' },
  standardHeaders: true,
  legacyHeaders: false
});