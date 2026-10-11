import mongoose from 'mongoose';

const coachSchema = new mongoose.Schema({
  nombre: { type: String, required: true, unique: true },
  especialidad: [String],

  // Horarios de atención. Formato: "lunes 06:00-12:00"
  // (día en minúsculas + rango 24 h; la app genera citas de 1 hora)
  disponibilidad: [String],

  calificacionPromedio: Number,
  clientesAsignados: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  // Perfil público (lo que ve el usuario al elegir entrenador)
  experiencia: Number,                 // años
  certificaciones: [String],
  descripcion: String,
  tipoEntrenamiento: String,
  precio: Number,                      // COP por mes
  descripcionPrecio: { type: String, default: '/mes' },
  servicios: [String],
  nivel: { type: String, enum: ['standard', 'premium', 'elite'], default: 'standard' },

  // Foto de perfil (Cloudinary o URL pública)
  fotoPerfil: String,
  fotoPerfilId: String
}, { collection: 'coaches' });

export default mongoose.model('Coach', coachSchema);