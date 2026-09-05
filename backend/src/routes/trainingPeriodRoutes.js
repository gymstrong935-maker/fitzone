import express from 'express';
import { crearPeriodo, obtenerPeriodosPorUsuario } from '../controllers/trainingPeriodController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';

const router = express.Router();
router.post('/', verificarToken, crearPeriodo);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerPeriodosPorUsuario);

export default router;