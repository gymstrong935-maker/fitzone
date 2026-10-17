// ======================================================
// PLANTILLAS DE CORREO DE FITZONE
// HTML con tablas y estilos en línea (compatible con Gmail/Outlook).
// ======================================================

export const MINUTOS_CODIGO = 15;

const FUENTE = "'Segoe UI','Helvetica Neue',Arial,sans-serif";

const C = {
  fondo: '#05080f',
  tarjeta: '#0b1220',
  borde: '#18283d',
  cian: '#06B6D4',
  cianClaro: '#22D3EE',
  turquesa: '#14B8A6',
  texto: '#E6EEF7',
  suave: '#9FB0C3',
  tenue: '#667789'
};

// Evita que un nombre con HTML "rompa" el correo
export const escapeHtml = (valor) =>
  String(valor ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

const parrafo = (html) =>
  `<p style="margin:0 0 16px 0;font-family:${FUENTE};font-size:15px;line-height:1.65;color:${C.suave};">${html}</p>`;

const resaltar = (texto) => `<strong style="color:${C.texto};">${texto}</strong>`;

const bloqueCodigo = (codigo) => `
  <table role="presentation" align="center" cellpadding="0" cellspacing="0" style="margin:26px auto 10px auto;">
    <tr>
      <td style="background:#06222c;border:1px solid #0e7490;border-radius:16px;padding:18px 30px;font-family:'Courier New',Courier,monospace;font-size:36px;font-weight:700;letter-spacing:12px;color:${C.cianClaro};text-align:center;">
        ${escapeHtml(codigo)}
      </td>
    </tr>
  </table>
  <p style="margin:0 0 22px 0;text-align:center;font-family:${FUENTE};font-size:13px;color:${C.tenue};">
    ⏱ Este código vence en ${MINUTOS_CODIGO} minutos
  </p>`;

const boton = (texto, url) => `
  <table role="presentation" align="center" cellpadding="0" cellspacing="0" style="margin:26px auto 6px auto;">
    <tr>
      <td style="border-radius:14px;background:${C.cian};background-image:linear-gradient(135deg,${C.cian},${C.turquesa});">
        <a href="${escapeHtml(url)}" style="display:inline-block;padding:14px 30px;font-family:${FUENTE};font-size:15px;font-weight:700;color:#04121a;text-decoration:none;border-radius:14px;">${escapeHtml(texto)}</a>
      </td>
    </tr>
  </table>`;

const urlApp = () => (process.env.APP_URL || '').trim();

// Da estilo al HTML sencillo que ya usa el resto del backend (<p>, <strong>, <ul>, <li>)
const estilizarContenido = (html) =>
  String(html ?? '')
    .replace(/<p>/g, `<p style="margin:0 0 16px 0;font-family:${FUENTE};font-size:15px;line-height:1.65;color:${C.suave};">`)
    .replace(/<strong>/g, `<strong style="color:${C.texto};">`)
    .replace(/<ul>/g, '<ul style="margin:0 0 16px 18px;padding:0;">')
    .replace(/<li>/g, `<li style="margin:0 0 6px 0;font-family:${FUENTE};font-size:15px;color:${C.suave};">`);

const layout = ({ preheader, titulo, contenido }) => `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="color-scheme" content="dark">
  <meta name="supported-color-schemes" content="dark">
  <title>${escapeHtml(titulo)}</title>
</head>
<body style="margin:0;padding:0;background:${C.fondo};">
  <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:${C.fondo};font-size:1px;">${escapeHtml(preheader)}</div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${C.fondo};">
    <tr>
      <td align="center" style="padding:32px 16px;">
        <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;background:${C.tarjeta};border:1px solid ${C.borde};border-radius:24px;overflow:hidden;">
          <tr>
            <td style="height:5px;line-height:5px;font-size:0;background:${C.cian};background-image:linear-gradient(90deg,${C.cian},${C.turquesa});">&nbsp;</td>
          </tr>
          <tr>
            <td style="padding:30px 36px 0 36px;">
              <table role="presentation" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="44" height="44" align="center" style="width:44px;height:44px;border-radius:22px;background:#0a2a36;border:1px solid #0e7490;font-family:${FUENTE};font-weight:700;font-size:16px;color:${C.cianClaro};">FZ</td>
                  <td style="padding-left:12px;font-family:${FUENTE};font-size:20px;font-weight:700;color:${C.texto};">
                    FitZone<br>
                    <span style="font-size:12px;font-weight:400;color:${C.tenue};">Tu entrenador personal digital</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:28px 36px 6px 36px;">
              <h1 style="margin:0 0 18px 0;font-family:${FUENTE};font-size:26px;line-height:1.25;font-weight:700;color:${C.texto};">${escapeHtml(titulo)}</h1>
              ${contenido}
            </td>
          </tr>
          <tr>
            <td style="padding:10px 36px 30px 36px;">
              <div style="height:1px;background:${C.borde};margin:0 0 18px 0;line-height:1px;font-size:0;">&nbsp;</div>
              <p style="margin:0;font-family:${FUENTE};font-size:12px;line-height:1.6;color:${C.tenue};">
                Este mensaje se envió automáticamente desde FitZone. Si no esperabas este correo, puedes ignorarlo con tranquilidad.
              </p>
            </td>
          </tr>
        </table>
        <p style="margin:18px 0 0 0;font-family:${FUENTE};font-size:11px;color:${C.tenue};">© ${new Date().getFullYear()} FitZone</p>
      </td>
    </tr>
  </table>
</body>
</html>`;

// ------------------------------------------------------
// Códigos
// ------------------------------------------------------

export const correoVerificacion = ({ nombre, codigo, reenvio = false }) => ({
  asunto: reenvio ? 'Tu nuevo código de verificación - FitZone' : 'Verifica tu correo - FitZone',
  html: layout({
    preheader: `Tu código es ${codigo}. Vence en ${MINUTOS_CODIGO} minutos.`,
    titulo: reenvio ? 'Tu nuevo código' : 'Verifica tu correo',
    contenido:
      parrafo(`Hola ${resaltar(escapeHtml(nombre))}, ${reenvio ? 'aquí tienes un código nuevo' : 'gracias por registrarte en FitZone'}. Escribe este código en la app para verificar tu correo:`) +
      bloqueCodigo(codigo) +
      parrafo('Cuando verifiques tu correo, el equipo de FitZone revisará y aprobará tu cuenta. Te avisaremos por aquí en cuanto esté lista.')
  })
});

export const correoRecuperacion = ({ nombre, codigo }) => ({
  asunto: 'Recupera tu contraseña - FitZone',
  html: layout({
    preheader: `Tu código es ${codigo}. Vence en ${MINUTOS_CODIGO} minutos.`,
    titulo: 'Recupera tu contraseña',
    contenido:
      parrafo(`Hola ${resaltar(escapeHtml(nombre))}, recibimos una solicitud para cambiar tu contraseña. Escribe este código en la app para crear una nueva:`) +
      bloqueCodigo(codigo) +
      parrafo('Si no fuiste tú, ignora este correo: tu contraseña actual sigue funcionando.')
  })
});

// ------------------------------------------------------
// Estado de la cuenta
// ------------------------------------------------------

export const correoCuentaAprobada = ({ nombre }) => ({
  asunto: '¡Tu cuenta fue aprobada! - FitZone',
  html: layout({
    preheader: 'Ya puedes continuar en FitZone.',
    titulo: '¡Tu cuenta fue aprobada! 🎉',
    contenido:
      parrafo(`Hola ${resaltar(escapeHtml(nombre))}, el equipo de FitZone aprobó tu cuenta. Ya puedes iniciar sesión y continuar con la configuración de tu perfil.`) +
      (urlApp() ? boton('Abrir FitZone', urlApp()) : '')
  })
});

export const correoCuentaRechazada = ({ nombre, motivo }) => ({
  asunto: 'Tu solicitud en FitZone - FitZone',
  html: layout({
    preheader: 'Revisamos tu solicitud de registro.',
    titulo: 'No pudimos aprobar tu cuenta',
    contenido:
      parrafo(`Hola ${resaltar(escapeHtml(nombre))}, revisamos tu solicitud de registro y por ahora no pudimos aprobarla.`) +
      (motivo ? parrafo(`${resaltar('Motivo:')} ${escapeHtml(motivo)}`) : '') +
      parrafo('Si crees que es un error, entra a la app y usa "Hablar con una persona" en el chat de soporte.')
  })
});

// ------------------------------------------------------
// Aviso genérico: envuelve el HTML sencillo que ya usa el resto del backend
// ------------------------------------------------------

export const correoAviso = ({ titulo, contenidoHtml }) => {
  const limpio = String(titulo || 'FitZone').replace(/^FitZone\s*[-–]\s*/i, '').trim() || 'FitZone';
  return layout({
    preheader: limpio,
    titulo: limpio,
    contenido: estilizarContenido(contenidoHtml) + (urlApp() ? boton('Abrir FitZone', urlApp()) : '')
  });
};