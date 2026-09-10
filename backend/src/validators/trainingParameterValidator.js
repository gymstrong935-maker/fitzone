import { z } from 'zod';

export const parametroSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  ejercicio: z.string().min(2, 'El nombre del ejercicio es obligatorio'),
  series: z.number().positive('Las series deben ser un número positivo').int('Las series deben ser un número entero'),
  repeticiones: z.number().positive('Las repeticiones deben ser un número positivo').int('Las repeticiones deben ser un número entero'),
  peso: z.number().min(0, 'El peso no puede ser negativo').optional(),
  duracionMinutos: z.number().positive('La duración debe ser un número positivo').optional()
});