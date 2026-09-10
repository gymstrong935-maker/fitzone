import express from 'express';
import { crearCondicion, obtenerCondicionPorUsuario } from '../controllers/physicalConditionController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';

const router = express.Router();
router.post('/', verificarToken, crearCondicion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerCondicionPorUsuario);

export default router;