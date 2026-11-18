// Suspensión (baneo) temporal de cuentas.
export const DIAS_SUSPENSION = 30;
const MS_DIA = 24 * 60 * 60 * 1000;

export const finSuspension = (desde = new Date()) => new Date(desde.getTime() + DIAS_SUSPENSION * MS_DIA);

// Si la suspensión ya terminó, la cuenta vuelve a estar activa.
// Devuelve true cuando levantó la suspensión.
export const levantarSiVencio = async (usuario) => {
  if (!usuario || usuario.estadoCuenta !== 'suspendido') return false;
  if (!usuario.suspendidoHasta || usuario.suspendidoHasta.getTime() > Date.now()) return false;

  usuario.estadoCuenta = 'activo';
  usuario.suspendidoHasta = undefined;
  usuario.motivoSuspension = undefined;
  await usuario.save();
  return true;
};

export const estaBloqueada = (usuario) =>
  ['inactivo', 'suspendido'].includes(usuario?.estadoCuenta);

// Cuerpo de la respuesta 403 cuando la cuenta está suspendida
export const respuestaSuspension = (usuario) => {
  const hasta = usuario?.suspendidoHasta;
  const fecha = hasta
    ? hasta.toLocaleDateString('es-CO', { day: 'numeric', month: 'long', year: 'numeric' })
    : null;

  return {
    mensaje: fecha
      ? `Tu cuenta está suspendida hasta el ${fecha}. Después de esa fecha podrás volver a entrar.`
      : 'Tu cuenta está suspendida. Contacta al equipo de FitZone.',
    codigo: 'CUENTA_SUSPENDIDA',
    hasta: hasta ? hasta.toISOString() : undefined,
    motivo: usuario?.motivoSuspension || undefined
  };
};
