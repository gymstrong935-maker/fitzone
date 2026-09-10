import express from 'express';
import { obtenerNotificacionesPorUsuario, marcarComoLeida } from '../controllers/notificationController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';

const router = express.Router();
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerNotificacionesPorUsuario);
router.put('/:id/leida', verificarToken, marcarComoLeida);

export default router;