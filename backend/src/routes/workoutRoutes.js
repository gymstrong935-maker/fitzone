import express from 'express';
import { crearSesion, obtenerSesionesPorUsuario } from '../controllers/workoutController.js';
import verificarToken, { verificarDueño, usuarioDelToken } from '../middleware/authMiddleware.js';
import checkSubscription from '../middleware/checkSubscription.js';
import validar from '../middleware/validar.js';
import { sesionSchema } from '../validators/workoutValidator.js';

const router = express.Router();

router.post('/', verificarToken, checkSubscription, usuarioDelToken, validar(sesionSchema), crearSesion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerSesionesPorUsuario);

export default router;