import express from 'express';
import { crearGrupo, obtenerGrupos, eliminarGrupo } from '../controllers/groupController.js';
import verificarToken, { verificarAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();
router.get('/', obtenerGrupos);
router.post('/', verificarToken, verificarAdmin, crearGrupo);
router.delete('/:id', verificarToken, verificarAdmin, eliminarGrupo);

export default router;