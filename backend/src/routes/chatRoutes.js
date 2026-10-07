import express from 'express';
import { chatearConAsistente } from '../controllers/chatController.js';
import tokenOpcional from '../middleware/tokenOpcional.js';
import { limitarChat } from '../middleware/rateLimiter.js';

const router = express.Router();
router.post('/', limitarChat, tokenOpcional, chatearConAsistente);

export default router;