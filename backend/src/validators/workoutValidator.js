import { z } from 'zod';

const ejercicioSchema = z.object({
  nombre: z.string().min(1).max(80),
  grupoMuscular: z.string().max(40).optional(),
  series: z.number().int().min(1).max(20),
  repeticiones: z.string().max(20)
});

export const sesionSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  clienteId: z.string().min(1).max(80).optional(),
  fecha: z.coerce.date().optional(),
  duracionMinutos: z.number().int().min(0, 'La duración no puede ser negativa').max(600),
  calorias: z.number().min(0).max(5000).optional(),
  pulsacionesReposo: z.number().int().min(20).max(250).optional(),
  fatiga: z.enum(['none', 'moderate', 'fatigued', 'high', 'veryHigh']).optional(),
  agujetas: z.enum(['none', 'light', 'moderate', 'intense']).optional(),
  ejercicios: z.array(ejercicioSchema).min(1, 'Debe haber al menos un ejercicio').max(30)
});