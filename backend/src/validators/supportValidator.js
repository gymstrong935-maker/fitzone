import { z } from 'zod';

export const ticketSchema = z.object({
  usuarioId: z.string().min(1),
  asunto: z.string().trim().min(3, 'El asunto debe tener al menos 3 caracteres').max(120),
  mensaje: z.string().trim().min(5, 'Cuéntanos un poco más (mínimo 5 caracteres)').max(2000),
  transcripcion: z.array(z.object({
    rol: z.enum(['user', 'assistant']),
    contenido: z.string().max(1000)
  })).max(20).optional()
});

export const mensajeTicketSchema = z.object({
  mensaje: z.string().trim().min(1, 'El mensaje no puede estar vacío').max(1000)
});