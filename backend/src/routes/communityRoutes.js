import express from 'express';
import rateLimit from 'express-rate-limit';
import {
  listarPosts, crearPost, eliminarPost, alternarLike,
  listarComentarios, crearComentario, eliminarComentario
} from '../controllers/communityController.js';
import verificarToken from '../middleware/authMiddleware.js';
import checkSubscription from '../middleware/checkSubscription.js';
import validar from '../middleware/validar.js';
import { postSchema, comentarioSchema } from '../validators/communityValidator.js';

const router = express.Router();

// Frena el spam al publicar, comentar o dar me gusta
const limitarEscritura = rateLimit({
  windowMs: 60 * 1000,
  max: process.env.NODE_ENV === 'production' ? 30 : 300,
  message: { mensaje: 'Vas muy rápido. Espera un momento e inténtalo de nuevo.' },
  standardHeaders: true,
  legacyHeaders: false
});

// Ver el muro: cualquier cuenta con sesión. Publicar y comentar: suscripción activa.
router.get('/', verificarToken, listarPosts);
router.post('/', verificarToken, checkSubscription, limitarEscritura, validar(postSchema), crearPost);
router.delete('/:id', verificarToken, eliminarPost);

router.post('/:id/like', verificarToken, limitarEscritura, alternarLike);

router.get('/:id/comentarios', verificarToken, listarComentarios);
router.post('/:id/comentarios', verificarToken, checkSubscription, limitarEscritura, validar(comentarioSchema), crearComentario);
router.delete('/:id/comentarios/:comentarioId', verificarToken, eliminarComentario);

export default router;
