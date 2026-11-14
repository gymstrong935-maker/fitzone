import mongoose from 'mongoose';

const workoutSessionSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  fecha: { type: Date, default: Date.now },
  duracionMinutos: { type: Number, default: 0 },
  calorias: { type: Number, default: 0 },

  ejercicios: [{
    nombre: String,
    grupoMuscular: String,
    series: Number,
    repeticiones: String
  }],

  // Post-entrenamiento
  pulsacionesReposo: Number,
  fatiga: String,    // none | moderate | fatigued | high | veryHigh
  agujetas: String,  // none | light | moderate | intense

  // Id generado en el dispositivo: evita duplicados al reintentar el envío
  clienteId: String
}, { collection: 'workout_sessions' });

workoutSessionSchema.index(
  { usuarioId: 1, clienteId: 1 },
  { unique: true, partialFilterExpression: { clienteId: { $type: 'string' } } }
);

export default mongoose.model('WorkoutSession', workoutSessionSchema);