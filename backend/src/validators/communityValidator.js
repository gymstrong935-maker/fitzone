import { z } from 'zod';

export const postSchema = z.object({
  texto: z.string().trim().max(280, 'El mensaje puede tener máximo 280 caracteres').optional(),
  entrenamientoId: z.string().regex(/^[a-fA-F0-9]{24}$/, 'Entrenamiento no válido').optional()
}).refine(
  (d) => Boolean(d.texto) || Boolean(d.entrenamientoId),
  { message: 'Escribe un mensaje o elige un entrenamiento para compartir' }
);

export const comentarioSchema = z.object({
  texto: z.string().trim().min(1, 'Escribe un comentario').max(300, 'El comentario puede tener máximo 300 caracteres')
});
