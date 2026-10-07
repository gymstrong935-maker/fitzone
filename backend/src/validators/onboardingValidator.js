import { z } from 'zod';

export const onboardingSchema = z.object({
  personal: z.object({
    edad: z.number().int().min(10).max(120),
    genero: z.enum(['male', 'female', 'other']),
    peso: z.number().positive().max(500),
    unidadPeso: z.enum(['kg', 'lb']),
    alturaCm: z.number().positive().max(300),
    condicionFisica: z.number().int().min(0).max(10),
    motivacion: z.number().int().min(0).max(10),
    estres: z.number().int().min(0).max(10),
    energia: z.number().int().min(0).max(10),
    condicionesMedicas: z.string().max(2000).optional().default('')
  }),
  mediciones: z.object({
    peso: z.number().positive().max(500),
    altura: z.number().positive().max(3),
    imc: z.number().positive().optional(),
    porcentajeGrasa: z.number().min(0).max(100).optional(),
    medidas: z.object({
      cintura: z.number().positive().optional(),
      cadera: z.number().positive().optional(),
      pecho: z.number().positive().optional(),
      brazo: z.number().positive().optional(),
      muslo: z.number().positive().optional(),
      pantorrilla: z.number().positive().optional()
    }).optional(),
    pliegues: z.record(z.string(), z.number().positive()).optional()
  }),
  objetivo: z.string().min(1).max(100),
  nivelExperiencia: z.enum(['beginner', 'intermediate', 'advanced']),
  habitos: z.object({
    frecuencia: z.number().int().min(1).max(7),
    duracionMinutos: z.number().int().min(30).max(120),
    calidadSueno: z.enum(['poor', 'fair', 'good', 'excellent']),
    horasSueno: z.number().min(0).max(24),
    nivelActividad: z.enum(['sedentary', 'light', 'moderate', 'active', 'very-active']),
    disponibilidad: z.array(z.string()).optional().default([])
  }),
  coachId: z.string().optional(),
  coachNombre: z.string().optional()
});
