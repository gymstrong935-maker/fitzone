import express from 'express';
import {
  registrarUsuario, iniciarSesion, obtenerUsuario,
  solicitarRecuperacion, restablecerPassword, actualizarUsuario,
  verificarCuenta, reenviarCodigo
} from '../controllers/userController.js';
import verificarToken, { verificarDueño } from '../middleware/authMiddleware.js';
import { limitarLogin, limitarRegistro, limitarRecuperacion } from '../middleware/rateLimiter.js';
import validar from '../middleware/validar.js';
import {
  registroSchema, loginSchema, forgotPasswordSchema, resetPasswordSchema,
  verificarCuentaSchema, reenviarCodigoSchema
} from '../validators/userValidator.js';
import crearUploadMiddleware from '../middleware/uploadMiddleware.js';

const router = express.Router();
const uploadUserImage = crearUploadMiddleware('users');

router.post('/register', limitarRegistro, validar(registroSchema), registrarUsuario);
router.post('/login', limitarLogin, validar(loginSchema), iniciarSesion);
router.post('/verificar-cuenta', validar(verificarCuentaSchema), verificarCuenta);
router.post('/reenviar-codigo', limitarRecuperacion, validar(reenviarCodigoSchema), reenviarCodigo);
router.post('/forgot-password', limitarRecuperacion, validar(forgotPasswordSchema), solicitarRecuperacion);
router.post('/reset-password/:token', validar(resetPasswordSchema), restablecerPassword);
router.get('/:id', verificarToken, verificarDueño, obtenerUsuario);
router.put('/:id', verificarToken, verificarDueño, uploadUserImage.single('imagen'), actualizarUsuario);

export default router;