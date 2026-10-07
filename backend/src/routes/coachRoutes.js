import express from 'express';
import { crearCoach, obtenerCoaches, actualizarCoach, eliminarCoach } from '../controllers/coachController.js';
import verificarToken, { verificarAdmin } from '../middleware/authMiddleware.js';
import crearUploadMiddleware from '../middleware/uploadMiddleware.js';

const router = express.Router();
const uploadCoachImage = crearUploadMiddleware('coaches');

router.get('/', obtenerCoaches);
router.post('/', verificarToken, verificarAdmin, uploadCoachImage.single('imagen'), crearCoach);
router.put('/:id', verificarToken, verificarAdmin, uploadCoachImage.single('imagen'), actualizarCoach);
router.delete('/:id', verificarToken, verificarAdmin, eliminarCoach);

export default router;