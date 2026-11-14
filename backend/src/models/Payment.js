import mongoose from 'mongoose';

// Métodos que la app ofrece hoy. "Sin definir" = el usuario aún no eligió.
// Los valores antiguos se conservan para no romper pagos ya guardados.
export const METODOS_PAGO = ['Efectivo', 'Pago digital'];

const paymentSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  suscripcionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subscription' },

  // suscripcion: pago de un plan · cambio_entrenador: diferencia por cambio de entrenador
  tipo: {
    type: String,
    enum: ['suscripcion', 'cambio_entrenador'],
    default: 'suscripcion'
  },
  solicitudCambioId: { type: mongoose.Schema.Types.ObjectId, ref: 'CoachChangeRequest' },

  monto: Number,
  metodoPago: {
    type: String,
    enum: [
      'Efectivo', 'Pago digital', 'Sin definir',
      'Transferencia bancaria', 'Nequi', 'Tarjeta'
    ],
    default: 'Sin definir'
  },

  // Factura / comprobante del pago digital (imagen en Cloudinary)
  comprobanteUrl: String,
  comprobanteId: String,
  fechaComprobante: Date,

  fechaPago: { type: Date, default: Date.now },
  estado: { type: String, enum: ['aprobado', 'pendiente', 'rechazado'], default: 'pendiente' },
  referenciaTransaccion: String,
  notaAdmin: String
}, { collection: 'payments' });

export default mongoose.model('Payment', paymentSchema);
