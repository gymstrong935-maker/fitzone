import express from 'express';
import { crearFrecuencia, obtenerFrecuenciaPorUsuario } from '../controllers/trainingFrequencyController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { frecuenciaSchema } from '../validators/trainingFrequencyValidator.js';

const router = express.Router();
router.post('/', verificarToken, validar(frecuenciaSchema), crearFrecuencia);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerFrecuenciaPorUsuario);

export default router;