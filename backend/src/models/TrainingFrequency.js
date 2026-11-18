import mongoose from 'mongoose';

const trainingFrequencySchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  diasPorSemana: Number,
  diasPreferidos: [String],
  horarioPreferido: String,
  duracionSesionMinutos: Number,
  nivelActividad: String
}, { collection: 'training_frequency' });

export default mongoose.model('TrainingFrequency', trainingFrequencySchema);