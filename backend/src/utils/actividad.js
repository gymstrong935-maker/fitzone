import ActivityLog from '../models/ActivityLog.js';
import User from '../models/User.js';

// Datos que jamás se guardan en el historial
const CAMPOS_PRIVADOS = new Set([
  'password', 'passwordActual', 'passwordNueva', 'confirmarPassword', 'nuevaPassword',
  'actualPassword', 'codigo', 'token', 'idToken', 'imagen', 'comprobante'
]);

const ETIQUETAS = {
  nombre: 'nombre', telefono: 'teléfono', edad: 'edad', genero: 'género', email: 'correo',
  rol: 'rol', estadoCuenta: 'estado de la cuenta'
};

export const camposDe = (body) =>
  Object.keys(body && typeof body === 'object' ? body : {})
    .filter((k) => !CAMPOS_PRIVADOS.has(k) && k !== 'usuarioId')
    .slice(0, 15);

export const etiquetaCampos = (campos) =>
  campos.map((c) => ETIQUETAS[c] || c).join(', ');

// Guarda una entrada. Nunca lanza: el historial no debe romper la acción original.
export const registrarActividad = async ({
  usuarioId, nombre, email, rol, categoria, accion, descripcion, objetivoId, objetivoNombre, detalle
}) => {
  try {
    let actor = { nombre, email, rol };

    if (usuarioId && (!nombre || !email)) {
      const u = await User.findById(usuarioId).select('nombre email rol').lean();
      if (u) actor = { nombre: u.nombre, email: u.email, rol: u.rol };
    }

    await ActivityLog.create({
      usuarioId: usuarioId || undefined,
      nombre: actor.nombre,
      email: actor.email,
      rol: actor.rol,
      categoria,
      accion,
      descripcion,
      objetivoId: objetivoId || undefined,
      objetivoNombre,
      detalle
    });
  } catch (error) {
    console.error('⚠️ No se pudo guardar el historial:', error.message);
  }
};
