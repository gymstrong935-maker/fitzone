import rateLimit from 'express-rate-limit';

const esProduccion = process.env.NODE_ENV === 'production';

// En desarrollo los límites son amplios para poder probar sin bloquearte.
const limite = (produccion, desarrollo) => (esProduccion ? produccion : desarrollo);

export const limitarLogin = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: limite(5, 100),
  message: { mensaje: 'Demasiados intentos. Intenta de nuevo en 15 minutos.' },
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

// El chat nunca responde con un error: avisa con un mensaje normal.
export const limitarChat = rateLimit({
  windowMs: 60 * 1000,
  max: limite(10, 100),
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) =>
    res.status(200).json({
      respuesta:
        'Estás escribiendo muy rápido. Dame unos segundos y vuelve a preguntarme, por favor.',
      origen: 'limite'
    })
});

export const limitarRecuperacion = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: limite(3, 100),
  message: { mensaje: 'Demasiadas solicitudes. Intenta más tarde.' },
  standardHeaders: true,
  legacyHeaders: false
});