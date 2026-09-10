import express from 'express';
import {
  crearCita, obtenerCitasPorEntrenador, obtenerCitasPorUsuario, cancelarCita
} from '../controllers/appointmentController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { citaSchema } from '../validators/appointmentValidator.js';

const router = express.Router();
router.post('/', verificarToken, validar(citaSchema), crearCita);
router.get('/entrenador/:entrenadorId', verificarToken, obtenerCitasPorEntrenador);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerCitasPorUsuario);
router.put('/:id/cancelar', verificarToken, cancelarCita);

export default router;