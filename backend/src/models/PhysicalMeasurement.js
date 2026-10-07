import mongoose from 'mongoose';

const physicalMeasurementSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  fecha: { type: Date, default: Date.now },
  peso: Number,
  altura: Number,
  imc: Number,
  porcentajeGrasa: Number,
  medidas: {
    cintura: Number,
    cadera: Number,
    pecho: Number,
    brazo: Number,
    muslo: Number,
    pantorrilla: Number
  },
  pliegues: {
    triceps: Number,
    subscapular: Number,
    chest: Number,
    abdominal: Number,
    thigh: Number,
    suprailiac: Number,
    midaxillary: Number
  }
}, { collection: 'physical_measurements' });

export default mongoose.model('PhysicalMeasurement', physicalMeasurementSchema);