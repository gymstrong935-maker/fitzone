import mongoose from 'mongoose';

const planSchema = new mongoose.Schema({
  nombre: { type: String, required: true, unique: true },
  duracionDias: Number,
  precio: Number,
  esGratuito: Boolean,
  beneficios: [String]
}, { collection: 'plans' });

export default mongoose.model('Plan', planSchema);