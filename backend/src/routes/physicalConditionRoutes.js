import express from 'express';
import { crearCondicion, obtenerCondicionPorUsuario } from '../controllers/physicalConditionController.js';
import verificarToken, { verificarDueño, usuarioDelToken } from '../middleware/authMiddleware.js';
import checkSubscription from '../middleware/checkSubscription.js';
import validar from '../middleware/validar.js';
import { condicionSchema } from '../validators/physicalConditionValidator.js';

const router = express.Router();
router.post('/', verificarToken, checkSubscription, usuarioDelToken, validar(condicionSchema), crearCondicion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerCondicionPorUsuario);

export default router;