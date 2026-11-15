// Horarios de atención de los entrenadores.
//
// Formato oficial (el que guarda el panel admin y lee la app):
//     "lunes 06:00-12:00"      (día en minúsculas + rango de 24 h)
//
// Este lector es tolerante para no perder horarios escritos a mano en Compass o
// en versiones anteriores. Entiende, por ejemplo:
//     "Lunes 6:00 AM - 12:00 PM"      "lun 06:00 a 12:00"
//     "lunes a viernes 6am-8pm"       "lunes, miércoles y viernes 14:00-20:00"
//     "sábado 8-12"                   "todos los días 18h-21h"
// Un horario con varios días se separa en un horario por día.

const NOMBRES_DIA = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const PREFIJOS_DIA = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];

const sinTildes = (texto) =>
  String(texto)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '');

const dosDigitos = (n) => String(n).padStart(2, '0');
export const aHHMM = (minutos) => `${dosDigitos(Math.floor(minutos / 60))}:${dosDigitos(minutos % 60)}`;

// "6:00 am" / "18h" / "6" -> minutos desde medianoche (o null)
const aMinutos = (hora, minutos, meridiano) => {
  let h = Number(hora);
  const m = minutos == null || minutos === '' ? 0 : Number(minutos);
  if (!Number.isFinite(h) || !Number.isFinite(m) || m > 59) return null;

  if (meridiano === 'pm' && h < 12) h += 12;
  if (meridiano === 'am' && h === 12) h = 0;
  if (h > 24 || (h === 24 && m > 0)) return null;

  return h * 60 + m;
};

const PATRON_HORA = '(\\d{1,2})(?:\\s*(?:[:.h]\\s*(\\d{2})?))?\\s*(am|pm)?';
const PATRON_RANGO = new RegExp(`^${PATRON_HORA}\\s*(?:-|a|al|hasta|to)\\s*${PATRON_HORA}$`);

// Parte de los días: "lunes", "lun-vie", "lunes a viernes", "lunes, miercoles y viernes"
const leerDias = (texto) => {
  const palabras = texto.match(/[a-z]+|[-,/&]/g) || [];
  const dias = new Set();
  let anterior = null; // último día leído
  let rango = false;   // venía un "a" / "-" entre dos días

  for (const palabra of palabras) {
    if (['a', 'al', 'hasta', '-'].includes(palabra)) {
      if (anterior != null) rango = true;
      continue;
    }

    if (['todos', 'diario', 'diarios', 'diaria', 'siempre'].includes(palabra)) {
      for (let d = 1; d <= 7; d++) dias.add(d);
      anterior = null;
      continue;
    }

    const indice = palabra.length >= 3 ? PREFIJOS_DIA.findIndex((p) => palabra.startsWith(p)) : -1;
    if (indice === -1) continue; // "los", "y", "de", comas...

    const dia = indice + 1;
    if (rango && anterior != null) {
      // Con vuelta a la semana: "viernes a lunes"
      for (let d = anterior; ; d = (d % 7) + 1) {
        dias.add(d);
        if (d === dia) break;
      }
    } else {
      dias.add(dia);
    }
    anterior = dia;
    rango = false;
  }

  return [...dias].sort((a, b) => a - b);
};

/**
 * Lee un horario escrito en texto libre.
 * @returns {{dias:number[], inicio:number, fin:number} | null}  dias: 1=lunes ... 7=domingo
 */
export const parsearHorario = (crudo) => {
  if (typeof crudo !== 'string') return null;

  let texto = sinTildes(crudo)
    .replace(/\b([ap])\s*\.\s*m\b\.?/g, '$1m') // "a. m." -> "am"
    .replace(/[–—]/g, '-')
    .replace(/\s+/g, ' ')
    .trim();

  const corte = texto.search(/\d/);
  if (corte === -1) return null;

  const dias = leerDias(texto.slice(0, corte));
  if (!dias.length) return null;

  const rango = PATRON_RANGO.exec(texto.slice(corte).trim());
  if (!rango) return null;

  const [, h1, m1, mer1, h2, m2, mer2] = rango;
  const fin = aMinutos(h2, m2, mer2);
  let inicio = aMinutos(h1, m1, mer1);

  // "2-8pm": si el inicio no dice am/pm, hereda el del final cuando tiene sentido
  if (!mer1 && mer2 && fin != null) {
    const heredado = aMinutos(h1, m1, mer2);
    if (heredado != null && heredado < fin) inicio = heredado;
  }

  if (inicio == null || fin == null) return null;
  if (fin < inicio + 60) return null; // la cita dura 1 hora: el rango debe caber al menos una

  return { dias, inicio, fin };
};

/**
 * Pasa una lista de horarios al formato oficial.
 * @returns {{validos:string[], invalidos:string[]}}
 */
export const normalizarDisponibilidad = (lista) => {
  const entradas = Array.isArray(lista) ? lista : lista == null || lista === '' ? [] : [lista];
  const validos = [];
  const invalidos = [];

  for (const entrada of entradas) {
    const horario = parsearHorario(entrada);

    if (!horario) {
      invalidos.push(String(entrada));
      continue;
    }

    for (const dia of horario.dias) {
      const texto = `${NOMBRES_DIA[dia - 1]} ${aHHMM(horario.inicio)}-${aHHMM(horario.fin)}`;
      if (!validos.includes(texto)) validos.push(texto);
    }
  }

  return { validos, invalidos };
};

/** Horas de inicio ("06:00", "07:00"...) que ofrece el entrenador un día de la semana (1=lunes ... 7=domingo). */
export const horasDelDia = (disponibilidad, diaSemana) => {
  const horas = new Set();

  for (const entrada of disponibilidad || []) {
    const horario = parsearHorario(entrada);
    if (!horario || !horario.dias.includes(diaSemana)) continue;

    for (let t = horario.inicio; t + 60 <= horario.fin; t += 60) horas.add(aHHMM(t));
  }

  return [...horas].sort();
};

/** Día de la semana (1=lunes ... 7=domingo) de una fecha "YYYY-MM-DD", o null si no existe. */
export const diaSemanaDe = (fecha) => {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(fecha || '');
  if (!m) return null;

  const [anio, mes, dia] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const d = new Date(Date.UTC(anio, mes - 1, dia));
  if (d.getUTCFullYear() !== anio || d.getUTCMonth() !== mes - 1 || d.getUTCDate() !== dia) return null;

  return d.getUTCDay() === 0 ? 7 : d.getUTCDay();
};

/** "Ahora" en la zona horaria del gimnasio, como { fecha: 'YYYY-MM-DD', hora: 'HH:MM' }. */
export const ahoraEnGimnasio = (zona = process.env.TZ_GIMNASIO || 'America/Bogota') => {
  const partes = Object.fromEntries(
    new Intl.DateTimeFormat('en-CA', {
      timeZone: zona, hourCycle: 'h23',
      year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit'
    }).formatToParts(new Date()).map((p) => [p.type, p.value])
  );

  return { fecha: `${partes.year}-${partes.month}-${partes.day}`, hora: `${partes.hour}:${partes.minute}` };
};
