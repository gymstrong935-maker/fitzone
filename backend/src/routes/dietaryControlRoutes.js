import express from 'express';
import { crearRegistroAlimentacion, obtenerAlimentacionPorUsuario } from '../controllers/dietaryControlController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { dietaSchema } from '../validators/dietaryControlValidator.js';

const router = express.Router();
router.post('/', verificarToken, validar(dietaSchema), crearRegistroAlimentacion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerAlimentacionPorUsuario);

export default router;