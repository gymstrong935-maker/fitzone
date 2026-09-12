import express from 'express';
import {
  crearNotificacion, obtenerNotificacionesPorUsuario,
  marcarComoLeida, marcarTodasComoLeidas
} from '../controllers/notificationController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';

const router = express.Router();
router.post('/', verificarToken, crearNotificacion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerNotificacionesPorUsuario);
router.put('/:id/leer', verificarToken, marcarComoLeida);
router.put('/usuario/:usuarioId/leer-todas', verificarToken, verificarDueño, marcarTodasComoLeidas);

export default router;