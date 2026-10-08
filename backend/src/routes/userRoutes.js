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
  reenviarCodigo,
  cambiarRolUsuario
} from '../controllers/userController.js';

import verificarToken, {
  verificarDueño,
  verificarAdmin
} from '../middleware/authMiddleware.js';

import {
  limitarLogin,
  limitarRegistro,
  limitarRecuperacion,
  limitarResetPassword
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

const uploadUserImage =
  crearUploadMiddleware('users');


// ======================================================
// REGISTRO
// ======================================================

router.post(
  '/register',
  limitarRegistro,
  validar(registroSchema),
  registrarUsuario
);


// ======================================================
// LOGIN
// ======================================================

router.post(
  '/login',
  limitarLogin,
  validar(loginSchema),
  iniciarSesion
);


// ======================================================
// LOGIN CON GOOGLE
// ======================================================

router.post(
  '/google',
  limitarLogin,
  iniciarSesionGoogle
);


// ======================================================
// VERIFICAR CUENTA
// ======================================================

router.post(
  '/verificar-cuenta',
  validar(verificarCuentaSchema),
  verificarCuenta
);


// ======================================================
// REENVIAR CÓDIGO
// ======================================================

router.post(
  '/reenviar-codigo',
  limitarRecuperacion,
  validar(reenviarCodigoSchema),
  reenviarCodigo
);


// ======================================================
// RECUPERAR CONTRASEÑA
// ======================================================

router.post(
  '/forgot-password',
  limitarRecuperacion,
  validar(forgotPasswordSchema),
  solicitarRecuperacion
);


// ======================================================
// RESTABLECER CONTRASEÑA
// ======================================================

router.post(
  '/reset-password',
  limitarResetPassword,
  validar(resetPasswordSchema),
  restablecerPassword
);


// ======================================================
// CAMBIAR ROL DE USUARIO
// SOLO ADMIN
// ======================================================

router.put(
  '/admin/rol',
  verificarToken,
  verificarAdmin,
  cambiarRolUsuario
);


// ======================================================
// OBTENER USUARIO
// ======================================================

router.get(
  '/:id',
  verificarToken,
  verificarDueño,
  obtenerUsuario
);


// ======================================================
// ACTUALIZAR USUARIO
// ======================================================

router.put(
  '/:id',
  verificarToken,
  verificarDueño,
  uploadUserImage.single('imagen'),
  actualizarUsuario
);


export default router;

