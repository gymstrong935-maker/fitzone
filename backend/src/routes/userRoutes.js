import express from 'express';

import {
  iniciarSesionGoogle,
  obtenerUsuario,
  actualizarUsuario,
  cambiarPassword,
  cambiarRolUsuario
} from '../controllers/userController.js';

import verificarToken, {
  verificarDueño,
  verificarAdmin
} from '../middleware/authMiddleware.js';

import { limitarLogin } from '../middleware/rateLimiter.js';

import crearUploadMiddleware from '../middleware/uploadMiddleware.js';

const router = express.Router();

const uploadUserImage = crearUploadMiddleware('users');


// ======================================================
// ÚNICO MÉTODO DE ACCESO: GOOGLE
// (registro e inicio de sesión son el mismo endpoint)
// ======================================================

router.post('/google', limitarLogin, iniciarSesionGoogle);


// ======================================================
// MÉTODOS ANTIGUOS (correo + contraseña): DESHABILITADOS
// Responden 410 para que cualquier cliente viejo sepa qué pasó.
// ======================================================

const soloGoogle = (req, res) =>
  res.status(410).json({
    mensaje: 'FitZone ahora solo permite ingresar con Google.',
    codigo: 'SOLO_GOOGLE'
  });

[
  '/register',
  '/login',
  '/verificar-cuenta',
  '/reenviar-codigo',
  '/forgot-password',
  '/reset-password',
  '/reset-password/:token'
].forEach((ruta) => router.post(ruta, soloGoogle));


// ======================================================
// CAMBIAR ROL DE USUARIO (SOLO ADMIN)
// ======================================================

router.put('/admin/rol', verificarToken, verificarAdmin, cambiarRolUsuario);


// ======================================================
// PERFIL
// ======================================================

router.get('/:id', verificarToken, verificarDueño, obtenerUsuario);

router.put(
  '/:id',
  verificarToken,
  verificarDueño,
  uploadUserImage.single('imagen'),
  actualizarUsuario
);

router.put('/:id/password', verificarToken, verificarDueño, cambiarPassword);


export default router;
