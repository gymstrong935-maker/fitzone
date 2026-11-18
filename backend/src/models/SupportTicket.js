import mongoose from 'mongoose';

const mensajeSchema = new mongoose.Schema({
  autor: { type: String, enum: ['admin', 'usuario'], required: true },
  mensaje: { type: String, required: true },
  fecha: { type: Date, default: Date.now }
}, { _id: false });

const supportTicketSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  asunto: { type: String, required: true },
  mensaje: { type: String, required: true },

  // Últimos mensajes de la conversación con el chatbot
  transcripcion: [{
    _id: false,
    rol: { type: String, enum: ['user', 'assistant'] },
    contenido: String
  }],

  estado: { type: String, enum: ['abierto', 'en_proceso', 'cerrado'], default: 'abierto', index: true },
  respuestas: [mensajeSchema]
}, { collection: 'support_tickets', timestamps: true });

export default mongoose.model('SupportTicket', supportTicketSchema);