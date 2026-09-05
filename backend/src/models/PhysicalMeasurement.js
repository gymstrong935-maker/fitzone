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
    brazo: Number
  }
}, { collection: 'physical_measurements' });

export default mongoose.model('PhysicalMeasurement', physicalMeasurementSchema);