import mongoose from 'mongoose';

// Copia del entrenamiento que se comparte: así la publicación no cambia
// aunque el usuario edite o borre su historial después.
const entrenamientoCompartidoSchema = new mongoose.Schema({
  entrenamientoId: { type: mongoose.Schema.Types.ObjectId, ref: 'WorkoutSession' },
  titulo: String,
  fecha: Date,
  duracionMinutos: Number,
  calorias: Number,
  ejercicios: [{
    _id: false,
    nombre: String,
    series: Number,
    repeticiones: String
  }]
}, { _id: false });

const postSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },

  texto: { type: String, default: '', maxlength: 280 },
  entrenamiento: { type: entrenamientoCompartidoSchema, default: undefined },

  likes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  comentarios: [{
    usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    texto: { type: String, required: true, maxlength: 300 },
    fecha: { type: Date, default: Date.now }
  }],

  // Se mantiene aparte para listar el muro sin traer todos los comentarios
  numComentarios: { type: Number, default: 0 }
}, { collection: 'publicaciones', timestamps: true });

postSchema.index({ createdAt: -1 });

export default mongoose.model('Post', postSchema);
