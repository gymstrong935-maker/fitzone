import mongoose from 'mongoose';

const physicalConditionSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  nivel: { type: String, enum: ['principiante', 'intermedio', 'avanzado'] },
  nivelExperiencia: { type: String, enum: ['beginner', 'intermediate', 'advanced'] },
  condicionFisica: { type: Number, min: 0, max: 10 },
  lesiones: [String],
  restricciones: [String],
  observacionesMedicas: String
}, { collection: 'physical_conditions' });

export default mongoose.model('PhysicalCondition', physicalConditionSchema);