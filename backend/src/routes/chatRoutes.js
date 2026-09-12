import express from 'express';
import { chatearConAsistente } from '../controllers/chatController.js';
import tokenOpcional from '../middleware/tokenOpcional.js';

const router = express.Router();
router.post('/', tokenOpcional, chatearConAsistente);

export default router;