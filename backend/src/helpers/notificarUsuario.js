import Notification from '../models/Notification.js';
import transporter from '../utils/mailer.js';

const notificarUsuario = async (usuario, { mensaje, asuntoCorreo, htmlCorreo }) => {
  try {
    await Notification.create({
      usuarioId: usuario._id,
      tipo: 'sistema',
      mensaje,
      leida: false
    });

    if (usuario.email) {
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: usuario.email,
        subject: asuntoCorreo,
        html: htmlCorreo
      });
    }
  } catch (error) {
    console.error('❌ Error al notificar al usuario:', error.message);
  }
};

export default notificarUsuario;