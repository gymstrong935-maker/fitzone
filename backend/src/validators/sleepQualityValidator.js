import { z } from 'zod';

export const suenoSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  horasDormidas: z.number().min(0, 'Las horas dormidas no pueden ser negativas').max(24, 'Las horas dormidas no pueden superar 24'),
  calidadPercibida: z.number().min(1, 'La calidad debe ser al menos 1').max(5, 'La calidad no puede superar 5'),
  interrupciones: z.number().min(0, 'Las interrupciones no pueden ser negativas').optional()
});