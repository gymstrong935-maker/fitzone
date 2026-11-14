import express from 'express';
import { crearTicket, misTickets, agregarMensaje } from '../controllers/supportController.js';
import verificarToken, { usuarioDelToken } from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { ticketSchema, mensajeTicketSchema } from '../validators/supportValidator.js';

const router = express.Router();

router.post('/', verificarToken, usuarioDelToken, validar(ticketSchema), crearTicket);
router.get('/mios', verificarToken, misTickets);
router.post('/:id/mensaje', verificarToken, validar(mensajeTicketSchema), agregarMensaje);

export default router;