import mongoose from 'mongoose';

const subscriptionSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  planId: { type: mongoose.Schema.Types.ObjectId, ref: 'Plan' },
  fechaInicio: Date,
  fechaFin: Date,
  estado: {
    type: String,
    enum: ['pendiente', 'activa', 'vencida', 'cancelada', 'rechazada'],
    default: 'activa'
  }
}, { collection: 'subscriptions' });

export default mongoose.model('Subscription', subscriptionSchema);