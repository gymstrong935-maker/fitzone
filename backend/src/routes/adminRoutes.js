import express from 'express';
import verificarToken, { verificarAdmin } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import {
  usuarioAdminSchema, planAdminSchema, grupoAdminSchema, anuncioSchema,
  respuestaTicketSchema, estadoTicketSchema, rechazoSchema
} from '../validators/adminValidator.js';
import {
  obtenerEstadisticas, listarUsuarios, detalleUsuario, actualizarUsuarioAdmin,
  aprobarCuenta, rechazarCuenta,
  listarSuscripciones, aprobarConPago, rechazarConPago, listarPagos,
  listarPlanes, actualizarPlan,
  listarGrupos, crearGrupo, actualizarGrupo, eliminarGrupo,
  listarCitas, enviarAnuncio,
  listarTickets, detalleTicket, responderTicket, cambiarEstadoTicket
} from '../controllers/adminController.js';
import { verificarVencimientos } from '../controllers/subscriptionController.js';

const router = express.Router();

// Todo este módulo es solo para administradores
router.use(verificarToken, verificarAdmin);

router.get('/stats', obtenerEstadisticas);

router.get('/users', listarUsuarios);
router.get('/users/:id', detalleUsuario);
router.put('/users/:id', validar(usuarioAdminSchema), actualizarUsuarioAdmin);
router.put('/users/:id/aprobar', aprobarCuenta);
router.put('/users/:id/rechazar', validar(rechazoSchema), rechazarCuenta);
router.post('/users/:id/revocar', validar(rechazoSchema), revocarCuenta);

router.get('/subscriptions', listarSuscripciones);
router.put('/subscriptions/:id/aprobar', aprobarConPago);
router.put('/subscriptions/:id/rechazar', rechazarConPago);
router.get('/payments', listarPagos);

router.get('/plans', listarPlanes);
router.put('/plans/:id', validar(planAdminSchema), actualizarPlan);

router.get('/groups', listarGrupos);
router.post('/groups', validar(grupoAdminSchema), crearGrupo);
router.put('/groups/:id', validar(grupoAdminSchema), actualizarGrupo);
router.delete('/groups/:id', eliminarGrupo);

router.get('/appointments', listarCitas);

router.post('/notifications', validar(anuncioSchema), enviarAnuncio);

router.get('/support', listarTickets);
router.get('/support/:id', detalleTicket);
router.post('/support/:id/responder', validar(respuestaTicketSchema), responderTicket);
router.put('/support/:id/estado', validar(estadoTicketSchema), cambiarEstadoTicket);

router.post('/maintenance/vencimientos', verificarVencimientos);

export default router;