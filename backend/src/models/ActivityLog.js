import mongoose from 'mongoose';

// Historial de cambios: qué hizo cada usuario (o el equipo) dentro de la app.
// Se guarda una "foto" del nombre y el correo para que el registro siga siendo
// legible aunque la cuenta se elimine después.
const activityLogSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  nombre: String,
  email: String,
  rol: String,

  // perfil · cuenta · entrenamiento · salud · citas · pagos · comunidad · soporte · admin
  categoria: { type: String, index: true },
  accion: { type: String, required: true },
  descripcion: { type: String, required: true },

  // Si la acción la hizo un administrador sobre otra cuenta
  objetivoId: { type: mongoose.Schema.Types.ObjectId },
  objetivoNombre: String,

  // Solo datos seguros (nombres de campos, ids...). Nunca contraseñas ni códigos.
  detalle: mongoose.Schema.Types.Mixed,

  fecha: { type: Date, default: Date.now, index: true }
}, { collection: 'activity_logs' });

// El historial se conserva 180 días y luego se borra solo
activityLogSchema.index({ fecha: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 180 });

export default mongoose.model('ActivityLog', activityLogSchema);
