import { z } from 'zod';

export const comidaSchema = z.object({
  tipo: z.enum(['desayuno', 'almuerzo', 'cena', 'snack']),
  alimentos: z.array(z.string()).min(1, 'Debe haber al menos un alimento'),
  calorias: z.number().min(0, 'Las calorías no pueden ser negativas')
});

export const dietaSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  comidas: z.array(comidaSchema).optional(),
  aguaLitros: z.number().min(0, 'El agua no puede ser negativa').max(20, 'Valor de agua no razonable').optional()
});