import Notification from '../models/Notification.js';
import { enviarCorreoSeguro } from '../utils/enviarCorreoSeguro.js';
import { correoAviso, escapeHtml } from '../utils/emailTemplates.js';

const notificarUsuario = async (usuario, { mensaje, asuntoCorreo, htmlCorreo }) => {
  try {
    await Notification.create({
      usuarioId: usuario._id,
      tipo: 'sistema',
      mensaje,
      leida: false
    });

    if (usuario.email) {
      await enviarCorreoSeguro({
        from: process.env.EMAIL_USER,
        to: usuario.email,
        subject: asuntoCorreo || 'FitZone',
        html: correoAviso({
          titulo: asuntoCorreo,
          contenidoHtml: htmlCorreo || `<p>${escapeHtml(mensaje)}</p>`
        })
      });
    }
  } catch (error) {
    console.error('❌ Error al notificar al usuario:', error.message);
  }
};

export default notificarUsuario;