import express from 'express';
import { crearParametro, obtenerParametrosPorUsuario } from '../controllers/trainingParameterController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { parametroSchema } from '../validators/trainingParameterValidator.js';

const router = express.Router();
router.post('/', verificarToken, validar(parametroSchema), crearParametro);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerParametrosPorUsuario);

export default router;