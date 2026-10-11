import Groq from 'groq-sdk';
import Plan from '../models/Plan.js';
import Coach from '../models/Coach.js';
import Group from '../models/Group.js';
import Subscription from '../models/Subscription.js';
import User from '../models/User.js';
import Appointment from '../models/Appointment.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// Convierte el historial recibido del cliente en mensajes válidos (máx. 8)
const limpiarHistorial = (historial) => {
  if (!Array.isArray(historial)) return [];

  return historial
    .filter((m) =>
      m &&
      ['user', 'assistant'].includes(m.rol) &&
      typeof m.contenido === 'string' &&
      m.contenido.trim().length > 0
    )
    .slice(-8)
    .map((m) => ({ role: m.rol, content: m.contenido.slice(0, 1000) }));
};

export const chatearConAsistente = async (req, res) => {
  try {
    const { mensaje, historial } = req.body;

    if (!mensaje || typeof mensaje !== 'string' || mensaje.trim().length === 0) {
      return res.status(400).json({ mensaje: 'El mensaje no puede estar vacío' });
    }

    if (mensaje.length > 500) {
      return res.status(400).json({ mensaje: 'El mensaje no puede superar los 500 caracteres' });
    }

    // Datos públicos: siempre disponibles para el asistente
    const [planes, entrenadores, grupos] = await Promise.all([
      Plan.find(),
      Coach.find().select('-clientesAsignados'),
      Group.find()
    ]);

    let contextoPersonal = '';

    // Si viene un token válido (req.usuario existe), agrega datos personales
    if (req.usuario?.id) {
      const usuario = await User.findById(req.usuario.id).populate('entrenadorAsignado', 'nombre');
      const suscripcion = await Subscription.findOne({ usuarioId: req.usuario.id, estado: 'activa' });

      if (usuario) {
        const planDelUsuario = suscripcion
          ? await Plan.findById(suscripcion.planId)
          : await Plan.findById(usuario.planActual);

        const hoy = new Date().toISOString().slice(0, 10);
        const citas = await Appointment
          .find({ usuarioId: req.usuario.id, estado: 'confirmada', fecha: { $gte: hoy } })
          .populate('entrenadorId', 'nombre')
          .sort({ fecha: 1, hora: 1 })
          .limit(5);

        contextoPersonal = `
Información del usuario que está hablando contigo (úsala solo si te pregunta por su propia cuenta):
- Nombre: ${usuario.nombre}
- Plan actual: ${planDelUsuario ? planDelUsuario.nombre : 'sin plan asignado'}
- Estado de su suscripción: ${suscripcion ? suscripcion.estado : 'sin suscripción activa'}
- Fecha de vencimiento: ${suscripcion?.fechaFin ? new Date(suscripcion.fechaFin).toLocaleDateString('es-CO') : 'N/A'}
- Entrenador asignado: ${usuario.entrenadorAsignado ? usuario.entrenadorAsignado.nombre : 'ninguno'}
- Próximas citas: ${citas.length ? citas.map((c) => `${c.fecha} ${c.hora} con ${c.entrenadorId?.nombre || 'su entrenador'}`).join('; ') : 'ninguna'}
        `;
      }
    }

    const contextoPublico = `
Eres el asistente virtual de FitZone, un gimnasio. Responde SIEMPRE en español, de forma breve (máximo 4 frases), amable y precisa, basándote SOLO en esta información real. No uses markdown, ni asteriscos, ni títulos: solo texto sencillo.

PLANES DISPONIBLES:
${planes.map((p) => `- ${p.nombre}: $${p.precio} COP (${p.duracionDias} días) - ${(p.beneficios || []).join(', ')}`).join('\n')}

ENTRENADORES:
${entrenadores.map((e) => `- ${e.nombre}: especialidad en ${(e.especialidad || []).join(', ')}${e.experiencia ? `, ${e.experiencia} años de experiencia` : ''}${e.precio ? `, $${e.precio} COP/mes` : ''}${e.disponibilidad?.length ? `, horarios: ${e.disponibilidad.join('; ')}` : ''}`).join('\n')}

GRUPOS DISPONIBLES:
${grupos.map((g) => `- ${g.nombre} (nivel ${g.nivel}): ${g.horario}`).join('\n')}
${contextoPersonal}

No inventes información que no esté aquí. Si te preguntan algo que no sabes, dile al usuario que consulte con un administrador.
    `;

    const respuesta = await groq.chat.completions.create({
      model: 'openai/gpt-oss-20b',
      messages: [
        { role: 'system', content: contextoPublico },
        ...limpiarHistorial(historial),
        { role: 'user', content: mensaje.trim() }
      ]
    });

    const textoRespuesta = respuesta.choices[0]?.message?.content || 'No pude generar una respuesta.';

    res.json({ respuesta: textoRespuesta });
  } catch (error) {
    console.error('❌ Error en el chat:', error.message);
    res.status(500).json({ error: error.message });
  }
};