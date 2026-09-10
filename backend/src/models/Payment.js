import mongoose from 'mongoose';

const paymentSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  suscripcionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subscription' },
  monto: Number,
  metodoPago: String,
  fechaPago: { type: Date, default: Date.now },
  estado: { type: String, enum: ['aprobado', 'pendiente', 'rechazado'], default: 'pendiente' },
  referenciaTransaccion: String
}, { collection: 'payments' });

export default mongoose.model('Payment', paymentSchema);