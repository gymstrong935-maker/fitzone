import mongoose from 'mongoose';

const physicalMeasurementSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  fecha: { type: Date, default: Date.now },
  peso: Number,            // siempre en kg
  altura: Number,          // siempre en metros
  imc: Number,
  porcentajeGrasa: Number,
  unidadPeso: { type: String, enum: ['kg', 'lb'], default: 'kg' }, // unidad que prefiere el usuario

  // Circunferencias (cm)
  medidas: {
    cintura: Number,
    cadera: Number,
    pecho: Number,
    brazo: Number,
    muslo: Number,
    pantorrilla: Number
  },

  // Pliegues cutáneos / plicometría (mm)
  pliegues: {
    triceps: Number,
    subescapular: Number,
    pecho: Number,
    abdominal: Number,
    muslo: Number,
    suprailiaco: Number,
    axilarMedio: Number
  }
}, { collection: 'physical_measurements' });

export default mongoose.model('PhysicalMeasurement', physicalMeasurementSchema);