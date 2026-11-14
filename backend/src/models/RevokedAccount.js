import mongoose from 'mongoose';

// Registro de correos cuya cuenta fue eliminada (revocada) por un administrador.
const revokedAccountSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  nombre: String,
  motivo: String,
  revocadaPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  fecha: { type: Date, default: Date.now }
}, { collection: 'revoked_accounts' });

export default mongoose.model('RevokedAccount', revokedAccountSchema);