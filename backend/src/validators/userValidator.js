import { z } from 'zod';

// El correo se guarda y se compara siempre en minúsculas y sin espacios.
const correo = z
  .string()
  .trim()
  .email('Correo electrónico inválido')
  .transform((e) => e.toLowerCase());

export const registroSchema = z.object({
  nombre: z.string().min(2, 'El nombre debe tener al menos 2 caracteres'),
  email: correo,
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres'),
  telefono: z.string().min(7, 'El teléfono debe tener al menos 7 dígitos').optional(),
  planId: z.string().min(1, 'El planId no puede estar vacío').optional(),
  metodoPago: z.enum(['Efectivo', 'Pago digital']).optional()
});

export const loginSchema = z.object({
  email: correo,
  password: z.string().min(1, 'La contraseña es obligatoria'),
  // Plan elegido en pantalla (opcional): quien ya tiene cuenta solo entra con su mismo plan
  planId: z.string().min(1).optional()
});

export const forgotPasswordSchema = z.object({
  email: correo
});

export const resetPasswordSchema = z.object({
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres')
});

// Restablecer con el código de 6 dígitos enviado al correo
export const resetConCodigoSchema = z.object({
  email: correo,
  codigo: z.string().regex(/^\d{6}$/, 'El código debe tener 6 dígitos'),
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres')
});

export const verificarCuentaSchema = z.object({
  email: correo,
  codigo: z.string().min(4, 'El código es obligatorio')
});

export const reenviarCodigoSchema = z.object({
  email: correo
});