import { z } from 'zod';

export const motivacionSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  nivelMotivacion: z.number().min(1, 'El nivel debe ser al menos 1').max(5, 'El nivel no puede superar 5'),
  comentario: z.string().max(500, 'El comentario no puede superar 500 caracteres').optional()
});