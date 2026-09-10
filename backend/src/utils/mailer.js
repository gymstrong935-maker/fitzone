import brevo from '@getbrevo/brevo';

const apiInstance = new brevo.TransactionalEmailsApi();
apiInstance.authentications['apiKey'].apiKey = process.env.BREVO_API_KEY;

const transporter = {
  sendMail: async ({ from, to, subject, html }) => {
    const correo = new brevo.SendSmtpEmail();
    correo.sender = { email: from || process.env.EMAIL_USER, name: 'FitZone' };
    correo.to = [{ email: to }];
    correo.subject = subject;
    correo.htmlContent = html;

    return await apiInstance.sendTransacEmail(correo);
  }
};

export default transporter;