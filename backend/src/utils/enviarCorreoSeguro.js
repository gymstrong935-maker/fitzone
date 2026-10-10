import transporter from './mailer.js';

// Envía un correo sin tumbar la petición si el proveedor falla.
export const enviarCorreoSeguro = async (opciones) => {
  try {
    await transporter.sendMail(opciones);
    return true;
  } catch (error) {
    console.error('❌ No se pudo enviar el correo:', error.message);
    return false;
  }
};