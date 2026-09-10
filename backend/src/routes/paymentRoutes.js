import express from 'express';
import { crearPago, obtenerPagosPorUsuario } from '../controllers/paymentController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { pagoSchema } from '../validators/paymentValidator.js';

const router = express.Router();
router.post('/', verificarToken, validar(pagoSchema), crearPago);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerPagosPorUsuario);

export default router;