import mongoose from 'mongoose';

const trainingPeriodSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  duracionSemanas: Number,
  fechaInicio: Date,
  fechaFin: Date,
  objetivo: String
}, { collection: 'training_periods' });

export default mongoose.model('TrainingPeriod', trainingPeriodSchema);