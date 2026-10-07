import express from 'express';
import {
  obtenerSuscripcionPorUsuario,
  verificarVencimientos, cambiarPlan, limpiarCanceladas,
  obtenerPendientes, aprobarSuscripcion, rechazarSuscripcion,
  obtenerMiSuscripcion
} from '../controllers/subscriptionController.js';
import verificarToken, { verificarDueño, verificarAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/me', verificarToken, obtenerMiSuscripcion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerSuscripcionPorUsuario);
router.post('/cambiar-plan', verificarToken, cambiarPlan);

// Solo admin
router.get('/pendientes', verificarToken, verificarAdmin, obtenerPendientes);
router.put('/:id/aprobar', verificarToken, verificarAdmin, aprobarSuscripcion);
router.put('/:id/rechazar', verificarToken, verificarAdmin, rechazarSuscripcion);
router.get('/verificar-vencimientos', verificarToken, verificarAdmin, verificarVencimientos);
router.delete('/limpiar-canceladas/:usuarioId', verificarToken, verificarAdmin, limpiarCanceladas);

export default router;