import mongoose from 'mongoose';

const dietaryControlSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  fecha: { type: Date, default: Date.now },
  comidas: [{
    tipo: { type: String, enum: ['desayuno', 'almuerzo', 'cena', 'snack'] },
    hora: String,               // "08:00"
    alimentos: [String],        // "Avena (80 g)"
    calorias: Number,
    proteina: Number,           // g
    carbohidratos: Number,      // g
    grasas: Number              // g
  }],
  aguaLitros: Number
}, { collection: 'dietary_control' });

export default mongoose.model('DietaryControl', dietaryControlSchema);