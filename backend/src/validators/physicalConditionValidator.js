import { z } from 'zod';

const valoracion = z.number().min(0).max(10).optional();

export const condicionSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  nivel: z.enum(['principiante', 'intermedio', 'avanzado']).optional(),
  lesiones: z.array(z.string().max(200)).max(30).optional(),
  restricciones: z.array(z.string().max(200)).max(30).optional(),
  observacionesMedicas: z.string().max(1000, 'Las observaciones no pueden superar 1000 caracteres').optional(),
  valoraciones: z.object({
    condicionFisica: valoracion,
    motivacion: valoracion,
    estres: valoracion,
    energia: valoracion
  }).optional()
});