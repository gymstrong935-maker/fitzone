import { z } from 'zod';

const gramos = z.number().min(0, 'No puede ser negativo').max(2000).optional();

export const comidaSchema = z.object({
  tipo: z.enum(['desayuno', 'almuerzo', 'cena', 'snack']),
  hora: z.string().regex(/^\d{2}:\d{2}$/, 'La hora debe tener el formato HH:MM').optional(),
  alimentos: z.array(z.string().min(1).max(120)).min(1, 'Debe haber al menos un alimento').max(30),
  calorias: z.number().min(0, 'Las calorías no pueden ser negativas').max(10000),
  proteina: gramos,
  carbohidratos: gramos,
  grasas: gramos
});

export const dietaSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  fecha: z.coerce.date().optional(),
  comidas: z.array(comidaSchema).optional(),
  aguaLitros: z.number().min(0, 'El agua no puede ser negativa').max(20, 'Valor de agua no razonable').optional()
});