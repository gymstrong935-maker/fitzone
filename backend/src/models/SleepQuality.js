import mongoose from 'mongoose';

const sleepQualitySchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  fecha: { type: Date, default: Date.now },
  horasDormidas: Number,
  calidadPercibida: Number,
  interrupciones: Number
}, { collection: 'sleep_quality' });

export default mongoose.model('SleepQuality', sleepQualitySchema);