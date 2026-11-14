import mongoose from 'mongoose';

// Solicitud de un usuario para cambiar de entrenador.
//  pendiente_pago : el nuevo entrenador cuesta más; falta que el usuario pague la diferencia
//  pendiente      : espera la validación del administrador (y del pago, si lo hay)
//  aprobada       : el admin confirmó el cambio (ya se asignó el nuevo entrenador)
//  rechazada      : el admin lo rechazó
//  cancelada      : el usuario la canceló
const coachChangeSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  entrenadorActualId: { type: mongoose.Schema.Types.ObjectId, ref: 'Coach' },
  entrenadorNuevoId: { type: mongoose.Schema.Types.ObjectId, ref: 'Coach', required: true },

  precioActual: { type: Number, default: 0 },
  precioNuevo: { type: Number, default: 0 },
  diferencia: { type: Number, default: 0 },

  pagoId: { type: mongoose.Schema.Types.ObjectId, ref: 'Payment' },

  estado: {
    type: String,
    enum: ['pendiente_pago', 'pendiente', 'aprobada', 'rechazada', 'cancelada'],
    default: 'pendiente'
  },
  motivoRechazo: String,
  fechaResolucion: Date
}, { collection: 'coach_change_requests', timestamps: true });

export default mongoose.model('CoachChangeRequest', coachChangeSchema);
