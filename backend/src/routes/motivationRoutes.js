import express from 'express';
import { crearRegistroMotivacion, obtenerMotivacionPorUsuario } from '../controllers/motivationController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { motivacionSchema } from '../validators/motivationValidator.js';

const router = express.Router();
router.post('/', verificarToken, validar(motivacionSchema), crearRegistroMotivacion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerMotivacionPorUsuario);

export default router;