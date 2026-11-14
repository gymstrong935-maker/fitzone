import { z } from 'zod';
 
// Rangos razonables; deben coincidir con los de la app (body_measurements.dart).
const cm = (nombre, min, max) =>
  z.number().min(min, `${nombre} debe estar entre ${min} y ${max} cm`)
    .max(max, `${nombre} debe estar entre ${min} y ${max} cm`).optional();
const mm = (nombre, min, max) =>
  z.number().min(min, `El pliegue ${nombre} debe estar entre ${min} y ${max} mm`)
    .max(max, `El pliegue ${nombre} debe estar entre ${min} y ${max} mm`).optional();
 
export const medicionSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  peso: z.number().min(20, 'El peso debe ser de al menos 20 kg').max(300, 'El peso no puede superar 300 kg'),
  altura: z.number().min(1, 'La altura debe ser de al menos 1 metro').max(2.5, 'La altura no puede superar 2.5 metros'),
  imc: z.number().positive('El IMC debe ser un número positivo').optional(),
  porcentajeGrasa: z.number().min(0, 'El porcentaje de grasa no puede ser negativo').max(100, 'El porcentaje de grasa no puede superar 100').optional(),
  unidadPeso: z.enum(['kg', 'lb']).optional(),
  medidas: z.object({
    cintura: cm('La cintura', 40, 200),
    cadera: cm('La cadera', 50, 200),
    pecho: cm('El pecho', 60, 200),
    brazo: cm('El brazo', 15, 70),
    muslo: cm('El muslo', 30, 110),
    pantorrilla: cm('La pantorrilla', 20, 70)
  }).optional(),
  pliegues: z.object({
    triceps: mm('tríceps', 2, 60),
    subescapular: mm('subescapular', 2, 60),
    pecho: mm('de pecho', 2, 60),
    abdominal: mm('abdominal', 2, 80),
    muslo: mm('de muslo', 2, 80),
    suprailiaco: mm('suprailíaco', 2, 70),
    axilarMedio: mm('axilar medio', 2, 60)
  }).optional()
});