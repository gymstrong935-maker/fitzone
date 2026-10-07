import express from 'express';
import { crearPeriodo, obtenerPeriodosPorUsuario } from '../controllers/trainingPeriodController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import checkSubscription from '../middleware/checkSubscription.js';

const router = express.Router();

router.post('/', verificarToken, checkSubscription, crearPeriodo);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerPeriodosPorUsuario);

export default router;