import express from 'express';
import verificarToken from '../middleware/authMiddleware.js';
import validar from '../middleware/validar.js';
import { onboardingSchema } from '../validators/onboardingValidator.js';
import { guardarOnboarding, obtenerOnboarding } from '../controllers/onboardingController.js';

const router = express.Router();

router.post('/', verificarToken, validar(onboardingSchema), guardarOnboarding);
router.get('/me', verificarToken, obtenerOnboarding);

export default router;
