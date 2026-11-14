import mongoose from 'mongoose';

const groupSchema = new mongoose.Schema({
  nombre: { type: String, required: true, unique: true },
  entrenadorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Coach' },
  nivel: String,
  horario: String,
  miembros: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }]
}, { collection: 'groups' });

export default mongoose.model('Group', groupSchema);