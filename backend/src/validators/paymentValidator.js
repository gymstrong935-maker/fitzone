import { z } from 'zod';

export const pagoSchema = z.object({
  usuarioId: z.string().min(1, 'El usuarioId es obligatorio'),
  suscripcionId: z.string().min(1, 'La suscripcionId es obligatoria').optional(),
  monto: z.number().positive('El monto debe ser un número positivo'),
  metodoPago: z.string().min(2, 'El método de pago es obligatorio'),
  estado: z.enum(['aprobado', 'pendiente', 'rechazado']).optional(),
  referenciaTransaccion: z.string().optional()
});