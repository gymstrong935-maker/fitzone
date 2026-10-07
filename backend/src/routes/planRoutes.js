import express from 'express';
import { crearPlan, obtenerPlanes, eliminarPlan } from '../controllers/planController.js';
import verificarToken, { verificarAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();
router.get('/', obtenerPlanes);
router.post('/', verificarToken, verificarAdmin, crearPlan);
router.delete('/:id', verificarToken, verificarAdmin, eliminarPlan);

export default router;