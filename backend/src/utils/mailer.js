import { BrevoClient } from '@getbrevo/brevo';

const brevo = new BrevoClient({
  apiKey: process.env.BREVO_API_KEY
});

// Mantiene la misma "forma" que nodemailer (transporter.sendMail({...}))
// para que ningún otro archivo del proyecto necesite cambiar
const transporter = {
  sendMail: async ({ from, to, subject, html }) => {
    return await brevo.transactionalEmails.sendTransacEmail({
      subject,
      htmlContent: html,
      sender: { name: 'FitZone', email: from || process.env.EMAIL_USER },
      to: [{ email: to }]
    });
  }
};

export default transporter;