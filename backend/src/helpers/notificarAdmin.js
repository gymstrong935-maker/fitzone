import User from '../models/User.js';
import Notification from '../models/Notification.js';
import transporter from '../utils/mailer.js';

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
        await transporter.sendMail({
          from: process.env.EMAIL_USER,
          to: admin.email,
          subject: asuntoCorreo,
          html: htmlCorreo
        });
      }
    }
  } catch (error) {
    console.error('❌ Error al notificar al admin:', error.message);
    // No relanzamos el error: si falla la notificación, no debe tumbar el registro del usuario
  }
};

export default notificarAdmin;