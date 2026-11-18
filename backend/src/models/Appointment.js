import mongoose from 'mongoose';

const appointmentSchema = new mongoose.Schema({
  entrenadorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Coach', required: true },
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  fecha: { type: String, required: true }, // formato "2026-08-25"
  hora: { type: String, required: true },  // formato "18:00"
  estado: { type: String, enum: ['confirmada', 'cancelada'], default: 'confirmada' }
}, { collection: 'citas' });

// Un mismo entrenador no puede tener dos citas CONFIRMADAS en la misma fecha y hora
appointmentSchema.index(
  { entrenadorId: 1, fecha: 1, hora: 1 },
  { unique: true, partialFilterExpression: { estado: 'confirmada' } }
);

export default mongoose.model('Appointment', appointmentSchema);