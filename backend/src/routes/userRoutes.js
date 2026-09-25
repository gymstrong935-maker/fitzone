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


// ===============================
// REGISTRO
// ===============================

router.post(
  '/register',
  limitarRegistro,
  validar(registroSchema),
  registrarUsuario
);


// ===============================
// INICIO DE SESIÓN NORMAL
// ===============================

router.post(
  '/login',
  limitarLogin,
  validar(loginSchema),
  iniciarSesion
);


// ===============================
// INICIO DE SESIÓN CON GOOGLE
// ===============================

router.post(
  '/google',
  iniciarSesionGoogle
);


// ===============================
// VERIFICAR CUENTA
// ===============================

router.post(
  '/verificar-cuenta',
  validar(verificarCuentaSchema),
  verificarCuenta
);


// ===============================
// REENVIAR CÓDIGO
// ===============================

router.post(
  '/reenviar-codigo',
  limitarRecuperacion,
  validar(reenviarCodigoSchema),
  reenviarCodigo
);


// ===============================
// RECUPERAR CONTRASEÑA
// ===============================

router.post(
  '/forgot-password',
  limitarRecuperacion,
  validar(forgotPasswordSchema),
  solicitarRecuperacion
);


// ===============================
// RESTABLECER CONTRASEÑA
// ===============================

router.post(
  '/reset-password/:token',
  validar(resetPasswordSchema),
  restablecerPassword
);


// ===============================
// OBTENER PERFIL
// ===============================

router.get(
  '/:id',
  verificarToken,
  verificarDueño,
  obtenerUsuario
);


// ===============================
// ACTUALIZAR PERFIL
// ===============================

router.put(
  '/:id',
  verificarToken,
  verificarDueño,
  uploadUserImage.single('imagen'),
  actualizarUsuario
);


export default router;