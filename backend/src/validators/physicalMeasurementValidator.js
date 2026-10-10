import { z } from 'zod';

const cm = z.number().positive().max(400).optional();
const mm = z.number().positive().max(100).optional();

export const medicionSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  peso: z.number().positive('El peso debe ser un número positivo').max(500, 'El peso no puede superar 500 kg'),
  altura: z.number().positive('La altura debe ser un número positivo').max(3, 'La altura no puede superar 3 metros'),
  imc: z.number().positive('El IMC debe ser un número positivo').optional(),
  porcentajeGrasa: z.number().min(0, 'El porcentaje de grasa no puede ser negativo').max(100, 'El porcentaje de grasa no puede superar 100').optional(),
  unidadPeso: z.enum(['kg', 'lb']).optional(),
  medidas: z.object({
    cintura: cm,
    cadera: cm,
    pecho: cm,
    brazo: cm,
    muslo: cm,
    pantorrilla: cm
  }).optional(),
  pliegues: z.object({
    triceps: mm,
    subescapular: mm,
    pecho: mm,
    abdominal: mm,
    muslo: mm,
    suprailiaco: mm,
    axilarMedio: mm
  }).optional()
});