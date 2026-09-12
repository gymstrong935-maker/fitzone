import express from 'express';
import { crearRegistroSueno, obtenerSuenoPorUsuario } from '../controllers/sleepQualityController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { suenoSchema } from '../validators/sleepQualityValidator.js';
import checkSubscription from '../middleware/checkSubscription.js';

const router = express.Router();
router.post('/', verificarToken, validar(suenoSchema), crearRegistroSueno);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerSuenoPorUsuario);
router.post('/', verificarToken, checkSubscription, crearRegistroSueno);

export default router;

