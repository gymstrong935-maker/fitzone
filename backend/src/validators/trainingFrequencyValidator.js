import { z } from 'zod';

export const frecuenciaSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  diasPorSemana: z.number().min(1, 'Debe ser al menos 1 día').max(7, 'No puede superar 7 días').int(),
  diasPreferidos: z.array(z.string()).optional(),
  horarioPreferido: z.string().optional()
});