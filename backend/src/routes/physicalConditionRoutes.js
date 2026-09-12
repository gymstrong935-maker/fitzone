import express from 'express';
import { crearCondicion, obtenerCondicionPorUsuario } from '../controllers/physicalConditionController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import checkSubscription from '../middleware/checkSubscription.js';

const router = express.Router();
router.post('/', verificarToken, crearCondicion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerCondicionPorUsuario);
router.post('/', verificarToken, checkSubscription, crearCondicion);
export default router;


