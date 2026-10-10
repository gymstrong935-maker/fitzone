import express from 'express';
import { crearPeriodo, obtenerPeriodosPorUsuario } from '../controllers/trainingPeriodController.js';
import verificarToken, { verificarDueño, usuarioDelToken } from '../middleware/authMiddleware.js';
import checkSubscription from '../middleware/checkSubscription.js';
import validar from '../middleware/validar.js';
import { periodoSchema } from '../validators/trainingPeriodValidator.js';

const router = express.Router();

router.post('/', verificarToken, checkSubscription, usuarioDelToken, validar(periodoSchema), crearPeriodo);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerPeriodosPorUsuario);

export default router;