import { z } from 'zod';

export const citaSchema = z.object({
  entrenadorId: z.string().min(1, 'El entrenadorId es obligatorio'),
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  fecha: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'La fecha debe tener formato YYYY-MM-DD'),
  hora: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'La hora debe tener formato HH:MM (24h)')
});