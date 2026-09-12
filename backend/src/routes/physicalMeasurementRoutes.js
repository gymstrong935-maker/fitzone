import express from 'express';
import { crearMedicion, obtenerMedicionesPorUsuario } from '../controllers/physicalMeasurementController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { medicionSchema } from '../validators/physicalMeasurementValidator.js';
import checkSubscription from '../middleware/checkSubscription.js';

const router = express.Router();
router.post('/', verificarToken, validar(medicionSchema), crearMedicion);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerMedicionesPorUsuario);
router.post('/', verificarToken, checkSubscription, crearMedicion);

export default router;

