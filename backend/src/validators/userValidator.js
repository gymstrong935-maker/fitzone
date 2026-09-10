import { z } from 'zod';

export const registroSchema = z.object({
  nombre: z.string().min(2, 'El nombre debe tener al menos 2 caracteres'),
  email: z.string().email('Correo electrónico inválido'),
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres'),
  telefono: z.string().min(7, 'El teléfono debe tener al menos 7 dígitos').optional(),
  planId: z.string().min(1, 'El planId no puede estar vacío').optional()
});

export const loginSchema = z.object({
  email: z.string().email('Correo electrónico inválido'),
  password: z.string().min(1, 'La contraseña es obligatoria')
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('Correo electrónico inválido')
});

export const resetPasswordSchema = z.object({
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres')
});

export const verificarCuentaSchema = z.object({
  email: z.string().email('Correo electrónico inválido'),
  codigo: z.string().min(4, 'El código es obligatorio')
});

export const reenviarCodigoSchema = z.object({
  email: z.string().email('Correo electrónico inválido')
});