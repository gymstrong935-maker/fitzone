import { z } from 'zod';

export const periodoSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  objetivo: z.string().min(2, 'El objetivo es obligatorio').max(80),
  duracionSemanas: z.number().int().min(1).max(104).optional(),
  fechaInicio: z.coerce.date().optional(),
  fechaFin: z.coerce.date().optional()
});