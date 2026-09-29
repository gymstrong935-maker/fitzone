import express from 'express';

import {
registrarUsuario,
iniciarSesion,
iniciarSesionGoogle,
obtenerUsuario,
solicitarRecuperacion,
restablecerPassword,
actualizarUsuario,
verificarCuenta,
reenviarCodigo
} from '../controllers/userController.js';

import verificarToken, {
verificarDueño
} from '../middleware/authMiddleware.js';

import {
limitarLogin,
limitarRegistro,
limitarRecuperacion
} from '../middleware/rateLimiter.js';

import validar from '../middleware/validar.js';

import {
registroSchema,
loginSchema,
forgotPasswordSchema,
resetPasswordSchema,
verificarCuentaSchema,
reenviarCodigoSchema
} from '../validators/userValidator.js';

import crearUploadMiddleware from '../middleware/uploadMiddleware.js';

const router = express.Router();

const uploadUserImage = crearUploadMiddleware('users');

// Registro
router.post(
'/register',
limitarRegistro,
validar(registroSchema),
registrarUsuario
);

// Inicio de sesión
router.post(
'/login',
limitarLogin,
validar(loginSchema),
iniciarSesion
);

// Inicio de sesión con Google
router.post(
'/google',
limitarLogin,
iniciarSesionGoogle
);

// Verificación de cuenta
router.post(
'/verificar-cuenta',
validar(verificarCuentaSchema),
verificarCuenta
);

// Reenviar código de verificación
router.post(
'/reenviar-codigo',
limitarRecuperacion,
validar(reenviarCodigoSchema),
reenviarCodigo
);

// Solicitar recuperación de contraseña
router.post(
'/forgot-password',
limitarRecuperacion,
validar(forgotPasswordSchema),
solicitarRecuperacion
);

// Restablecer contraseña
router.post(
'/reset-password/:token',
validar(resetPasswordSchema),
restablecerPassword
);

// Obtener usuario
router.get(
'/:id',
verificarToken,
verificarDueño,
obtenerUsuario
);

// Actualizar usuario
router.put(
'/:id',
verificarToken,
verificarDueño,
uploadUserImage.single('imagen'),
actualizarUsuario
);

export default router;
