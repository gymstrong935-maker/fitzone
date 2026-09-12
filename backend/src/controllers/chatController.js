import Groq from 'groq-sdk';
import Plan from '../models/Plan.js';
import Coach from '../models/Coach.js';
import Group from '../models/Group.js';
import Subscription from '../models/Subscription.js';
import User from '../models/User.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

export const chatearConAsistente = async (req, res) => {
  try {
    const { mensaje } = req.body;

    if (!mensaje || typeof mensaje !== 'string' || mensaje.trim().length === 0) {
      return res.status(400).json({ mensaje: 'El mensaje no puede estar vacío' });
    }

    // Datos públicos: siempre disponibles para el asistente
    const [planes, entrenadores, grupos] = await Promise.all([
      Plan.find(),
      Coach.find(),
      Group.find()
    ]);

    let contextoPersonal = '';

    // Si viene un token válido (req.usuario existe), agrega datos personales
  if (req.usuario?.id) {
  const usuario = await User.findById(req.usuario.id);
  const suscripcion = await Subscription.findOne({ usuarioId: req.usuario.id, estado: 'activa' });

  if (usuario) {
    const planDelUsuario = suscripcion
      ? await Plan.findById(suscripcion.planId)
      : await Plan.findById(usuario.planActual);

    contextoPersonal = `
Información del usuario que está hablando contigo (usa esto solo si te pregunta por su propia cuenta):
- Nombre: ${usuario.nombre}
- Plan actual: ${planDelUsuario ? planDelUsuario.nombre : 'sin plan asignado'}
- Estado de su suscripción: ${suscripcion ? suscripcion.estado : 'sin suscripción activa'}
- Fecha de vencimiento: ${suscripcion?.fechaFin ? new Date(suscripcion.fechaFin).toLocaleDateString() : 'N/A'}
    `;
  }
}

    const contextoPublico = `
Eres el asistente virtual de FitZone, un gimnasio. Responde de forma breve, amable y precisa, basándote SOLO en esta información real:

PLANES DISPONIBLES:
${planes.map(p => `- ${p.nombre}: $${p.precio} (${p.duracionDias} días) - ${p.beneficios.join(', ')}`).join('\n')}

ENTRENADORES:
${entrenadores.map(e => `- ${e.nombre}: especialidad en ${e.especialidad.join(', ')}`).join('\n')}

GRUPOS DISPONIBLES:
${grupos.map(g => `- ${g.nombre} (nivel ${g.nivel}): ${g.horario}`).join('\n')}
${contextoPersonal}

No inventes información que no esté aquí. Si te preguntan algo que no sabes, dile al usuario que consulte con un administrador.
    `;

    const respuesta = await groq.chat.completions.create({
      model: 'openai/gpt-oss-20b',
      messages: [
        { role: 'system', content: contextoPublico },
        { role: 'user', content: mensaje }
      ]
    });

    const textoRespuesta = respuesta.choices[0]?.message?.content || 'No pude generar una respuesta.';

    res.json({ respuesta: textoRespuesta });
  } catch (error) {
    console.error('❌ Error en el chat:', error.message);
    res.status(500).json({ error: error.message });
  }
};