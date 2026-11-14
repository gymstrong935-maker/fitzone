import express from 'express';
import {
  crearPago, obtenerPagosPorUsuario, obtenerMisPagos, registrarComprobante
} from '../controllers/paymentController.js';
import verificarToken, { verificarDueño, verificarAdmin } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { pagoSchema } from '../validators/paymentValidator.js';
import crearUploadMiddleware from '../middleware/uploadMiddleware.js';

const router = express.Router();

// Las facturas necesitan más resolución que una foto de perfil
const uploadComprobante = crearUploadMiddleware('comprobantes', { maxLado: 1600 });

const subirComprobante = (req, res, next) =>
  uploadComprobante.single('comprobante')(req, res, (err) => {
    if (err) {
      return res.status(400).json({
        mensaje: err.code === 'LIMIT_FILE_SIZE'
          ? 'La imagen supera los 5 MB.'
          : (err.message || 'No se pudo subir la imagen')
      });
    }
    next();
  });

router.post('/', verificarToken, verificarAdmin, validar(pagoSchema), crearPago);
router.get('/mios', verificarToken, obtenerMisPagos);
router.put('/:id/comprobante', verificarToken, subirComprobante, registrarComprobante);
router.get('/usuario/:usuarioId', verificarToken, verificarDueño, obtenerPagosPorUsuario);

export default router;
