import { z } from 'zod';

const estadoTicket = z.enum(['abierto', 'en_proceso', 'cerrado']);

export const usuarioAdminSchema = z.object({
  nombre: z.string().trim().min(2, 'El nombre debe tener al menos 2 caracteres').max(60).optional(),
  telefono: z.string().trim().max(30).optional(),
  rol: z.string().min(1).max(30).optional(),
  estadoCuenta: z.string().min(1).max(30).optional()
});

export const planAdminSchema = z.object({
  nombre: z.string().trim().min(2).max(60),
  precio: z.number().min(0).max(100000000),
  duracionDias: z.number().int().min(1).max(3650),
  beneficios: z.array(z.string().trim().min(1).max(120)).max(12)
});

export const grupoAdminSchema = z.object({
  nombre: z.string().trim().min(2).max(60),
  nivel: z.string().trim().max(30).optional(),
  horario: z.string().trim().max(80).optional(),
  entrenadorId: z.string().nullable().optional()
});

export const anuncioSchema = z.object({
  destino: z.enum(['todos', 'activos', 'usuario']),
  email: z.string().email('Correo electrónico inválido').optional(),
  tipo: z.enum(['pago', 'recordatorio', 'entrenamiento', 'sistema']).default('sistema'),
  mensaje: z.string().trim().min(3, 'El mensaje es muy corto').max(300, 'Máximo 300 caracteres')
}).refine((d) => d.destino !== 'usuario' || !!d.email, {
  message: 'Escribe el correo del usuario',
  path: ['email']
});

export const respuestaTicketSchema = z.object({
  mensaje: z.string().trim().min(1, 'La respuesta no puede estar vacía').max(1000),
  estado: estadoTicket.optional()
});

export const estadoTicketSchema = z.object({ estado: estadoTicket });