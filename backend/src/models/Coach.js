import mongoose from 'mongoose';

const coachSchema = new mongoose.Schema({
  nombre: { type: String, required: true, unique: true },
  especialidad: [String],
  disponibilidad: [String],
  calificacionPromedio: Number,
  clientesAsignados: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  // Foto de perfil (Cloudinary)
  fotoPerfil: String,
  fotoPerfilId: String
}, { collection: 'coaches' });

export default mongoose.model('Coach', coachSchema);