import nodemailer from 'nodemailer';
import { BrevoClient } from '@getbrevo/brevo';

// Proveedor principal: Brevo (API HTTP, funciona en Render).
const brevo = process.env.BREVO_API_KEY
  ? new BrevoClient({ apiKey: process.env.BREVO_API_KEY })
  : null;

// Respaldo: Gmail con contraseña de aplicación (EMAIL_USER + EMAIL_PASS).
// Solo se usa si Brevo no está configurado o falla.
const gmail =
  process.env.EMAIL_USER && process.env.EMAIL_PASS
    ? nodemailer.createTransport({
        service: 'gmail',
        auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS }
      })
    : null;

const transporter = {
  sendMail: async ({ from, to, subject, html }) => {
    const remitente = from || process.env.EMAIL_USER;
    let errorBrevo = null;

    if (brevo) {
      try {
        return await brevo.transactionalEmails.sendTransacEmail({
          subject,
          htmlContent: html,
          sender: { name: 'FitZone', email: remitente },
          to: [{ email: to }]
        });
      } catch (error) {
        errorBrevo = error;
        console.error('⚠️ Brevo no pudo enviar el correo:', error.message);
      }
    }

    if (gmail) {
      return await gmail.sendMail({
        from: `"FitZone" <${remitente}>`,
        to,
        subject,
        html
      });
    }

    throw errorBrevo || new Error('No hay un proveedor de correo configurado (BREVO_API_KEY o EMAIL_PASS)');
  }
};

export default transporter;
