import mongoose from 'mongoose';

const dietaryControlSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  fecha: { type: Date, default: Date.now },
  comidas: [{
    tipo: { type: String, enum: ['desayuno', 'almuerzo', 'cena', 'snack'] },
    alimentos: [String],
    calorias: Number
  }],
  aguaLitros: Number
}, { collection: 'dietary_control' });

export default mongoose.model('DietaryControl', dietaryControlSchema);