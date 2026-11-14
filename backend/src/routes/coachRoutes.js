import express from 'express';
import {
  crearCoach, obtenerCoaches, actualizarCoach, eliminarCoach, asignarmeEntrenador
} from '../controllers/coachController.js';
import {
  solicitarCambioEntrenador, miSolicitudCambio, cancelarSolicitudCambio
} from '../controllers/coachChangeController.js';
import verificarToken, { verificarAdmin } from '../middleware/authMiddleware.js';
import crearUploadMiddleware from '../middleware/uploadMiddleware.js';

const router = express.Router();
const uploadCoachImage = crearUploadMiddleware('coaches');

router.get('/', obtenerCoaches);
router.get('/cambio/mia', verificarToken, miSolicitudCambio);
router.post('/cambio', verificarToken, solicitarCambioEntrenador);
router.delete('/cambio/:id', verificarToken, cancelarSolicitudCambio);
router.put('/:id/asignarme', verificarToken, asignarmeEntrenador);
router.post('/', verificarToken, verificarAdmin, uploadCoachImage.single('imagen'), crearCoach);
router.put('/:id', verificarToken, verificarAdmin, uploadCoachImage.single('imagen'), actualizarCoach);
router.delete('/:id', verificarToken, verificarAdmin, eliminarCoach);

export default router;