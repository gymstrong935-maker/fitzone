import User from '../models/User.js';
import Notification from '../models/Notification.js';
import { enviarCorreoSeguro } from '../utils/enviarCorreoSeguro.js';
import { correoAviso, escapeHtml } from '../utils/emailTemplates.js';

const notificarAdmin = async ({ mensaje, asuntoCorreo, htmlCorreo }) => {
  try {
    const admins = await User.find({ rol: 'admin' });

    for (const admin of admins) {
      // Notificación interna en la app
      await Notification.create({
        usuarioId: admin._id,
        tipo: 'sistema',
        mensaje,
        leida: false
      });

      // Correo al admin
      if (admin.email) {
        await enviarCorreoSeguro({
          from: process.env.EMAIL_USER,
          to: admin.email,
          subject: asuntoCorreo || 'FitZone',
          html: correoAviso({
            titulo: asuntoCorreo,
            contenidoHtml: htmlCorreo || `<p>${escapeHtml(mensaje)}</p>`
          })
        });
      }
    }
  } catch (error) {
    // Si falla el aviso, no debe tumbar el registro del usuario
    console.error('❌ Error al notificar al admin:', error.message);
  }
};

export default notificarAdmin;