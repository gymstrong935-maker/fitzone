import mongoose from 'mongoose';

const physicalConditionSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  nivel: { type: String, enum: ['principiante', 'intermedio', 'avanzado'] },
  lesiones: [String],
  restricciones: [String],
  observacionesMedicas: String,

  // Valoraciones originales del onboarding (escala 0 a 10)
  valoraciones: {
    condicionFisica: Number,
    motivacion: Number,
    estres: Number,
    energia: Number
  }
}, { collection: 'physical_conditions' });

export default mongoose.model('PhysicalCondition', physicalConditionSchema);