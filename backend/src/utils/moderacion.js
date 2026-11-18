// ======================================================
// MODERACIÓN DE LENGUAJE
// ------------------------------------------------------
// Detecta groserías, insultos, odio y amenazas en español (con variantes
// colombianas, mexicanas, argentinas, chilenas y venezolanas) aunque el usuario
// intente esquivar el filtro:
//   · "puuuuta", "hijueeeputa"      → letras repetidas
//   · "h1jueputa", "p3nd3j0", "m!erda" → números/símbolos en lugar de letras
//   · "p u t a", "p.u.t.a", "p-u-t-a"   → letras separadas
//   · "PUTA", "Púta"                → mayúsculas y tildes
//
// IMPORTANTE: la comparación es por PALABRA COMPLETA (no por pedazos de texto),
// así "computadora", "Vergara" o "disputa" no se bloquean por error.
// Tampoco se incluyen palabras que en un gimnasio son normales: "PR" (récord
// personal), "pm" (5 pm), "loco", "animal", "bruto", "culo", "coger una pesa",
// "comida basura", "golpe", "matar el hambre", etc.
// ======================================================

// ------------------------------------------------------
// 1. Lista de palabras (ya sin tildes, en minúsculas)
// ------------------------------------------------------

// Groserías y vulgaridades
const GROSERIAS = [
  // puta y derivados
  'puta', 'putas', 'puto', 'putos', 'putita', 'putito', 'putica', 'puteria', 'putear',
  'puteada', 'puteado', 'putazo', 'putamadre', 'putisima', 'putisimo', 'ptm', 'hdp',
  'hdtpm', 'hpta', 'hptas', 'hijueputa', 'hijueputas', 'hijuep', 'hijuepucha', 'hijoeputa',
  'hijodeputa', 'hijodeperra', 'hijuemadre', 'hijueputica', 'puton', 'putona', 'putarron',
  // gonorrea, malparido y derivados (muy colombianos)
  'gonorrea', 'gonorreas', 'gonorreo', 'gonorreico', 'gonorreica', 'malparido', 'malparida',
  'malparidos', 'malparidas', 'mamaguevo', 'mamagueva', 'mamahuevo', 'mamahuevos', 'mamaguevos',
  'mamagüevo', 'comemierda', 'comemierdas', 'tragaverga', 'chupaverga', 'lameculo', 'lameculos',
  // verga, mierda, joder, carajo
  'verga', 'vergas', 'vergazo', 'vergon', 'vergudo', 'vergajo', 'vrg', 'vrga',
  'mierda', 'mierdas', 'mierdero', 'mierdoso', 'mierdosa', 'mrd', 'mrda',
  'joder', 'jodete', 'jodido', 'jodida', 'jodidos', 'jodidas', 'jodiendo', 'jodan',
  'carajo', 'carajos', 'carajada', 'carajadas',
  'cagada', 'cagadas', 'cagar', 'cagon', 'cagona', 'cagando',
  // pendejo, cabrón, marica
  'pendejo', 'pendeja', 'pendejos', 'pendejas', 'pendejada', 'pendejadas', 'pendejito', 'pndj', 'pndjo',
  'cabron', 'cabrona', 'cabrones', 'cabronas', 'cabronada', 'cabronazo', 'cbrn',
  'marica', 'maricas', 'maricon', 'maricona', 'maricones', 'mariconada', 'mariconazo',
  'mariquita', 'marimacha', 'joto', 'jotos', 'tortillera', 'tortilleras',
  // mexicanas, argentinas, chilenas, venezolanas, españolas
  'chingada', 'chingado', 'chingar', 'chingon', 'chingona', 'chinga', 'chingas', 'chingate',
  'pinche', 'pinches', 'nomames', 'culero', 'culera', 'culiao', 'culiado', 'culiada',
  'boludo', 'boluda', 'boludos', 'boludas', 'pelotudo', 'pelotuda', 'pelotudos',
  'conchatumadre', 'conchudo', 'ctm', 'ctmr', 'ctmre', 'weon', 'weona', 'weones', 'hueon', 'hueona',
  'aweonao', 'aweonada', 'arrecho', 'follar', 'follando', 'follada', 'gilipollas', 'capullo'
];

// Insultos directos a otras personas
const INSULTOS = [
  'idiota', 'idiotas', 'idioteces', 'imbecil', 'imbeciles', 'imbecilidad',
  'estupido', 'estupida', 'estupidos', 'estupidas', 'estupidez', 'estupideces',
  'retrasado', 'retrasada', 'retrasados', 'retrasadas', 'mongolico', 'mongolica', 'subnormal',
  'subnormales', 'sinverguenza', 'sinverguenzas', 'desgraciado', 'desgraciada', 'desgraciados',
  'pedazodemierda'
];

// Odio y discriminación (insultos por origen, raza, orientación...)
const ODIO = [
  'nigger', 'nigga', 'negrata', 'sudaca', 'faggot', 'tranny', 'indiodemierda',
  'gordodemierda', 'gordademierda', 'hitleriano', 'kkk', 'nazi'
];

// Palabras que SOLO son odio en ciertas frases ("nazi" suelta es ambigua: se evalúa por frase)
const ODIO_SOLO_EN_FRASE = new Set(['nazi']);

// Frases (se evalúan sobre el texto normalizado: sin tildes, con las palabras separadas por un espacio)
const FRASES = [
  // Groserías en frase
  [/\bhij[oa] de (la )?(gran |re |remil |rec[ie]n )?(put[ao]|perr[ao]|mil put[ao]s|su (puta )?madre|la chingada)\b/, 'groseria'],
  [/\b(vete|andate|anda|vayase|largate|vayanse) (a la|al|a|para la|pa la|pal) (mierda|verga|carajo|chingada|cagar|diablo|vrg|alv|infierno)\b/, 'groseria'],
  [/\b(me|te|se) cago (en|de)\b/, 'groseria'],
  [/\bme (vale|importa) (verga|madre|mierda|un carajo|un culo|un huevo|un pepino)\b/, 'groseria'],
  [/\b(chupa|chupame|chupala|mamame|mamala|come) (mierda|verga|pene|huevo)\b/, 'groseria'],
  [/\balv\b/, 'groseria'],
  [/\bno mames\b/, 'groseria'],
  // Insultos en frase ("la comida es basura" NO se bloquea: solo cuando se lo dicen a alguien)
  [/\b(eres|sos|erez) (un |una |re |puro |pura |unos |unas )?(basura|fracasad[oa]s?|inutil(es)?|perdedor(a|es)?|asqueros[oa]s?|payas[oa]|perr[ao]s?|zorr[ao]s?|cerd[oa]s?|rata sucia|bobo|boba|tont[oa]s?|estupid[oa]s?|gord[oa] de mierda)\b/, 'insulto'],
  [/\bno (sirves|vales|sirven|valen) (para )?(nada|un carajo|ni mierda)\b/, 'insulto'],
  [/\bmaldit[oa]s? (infeliz|desgraciad[oa]|bastard[oa])\b/, 'insulto'],
  [/\b(infeliz|bastard[oa]|miserable) de mierda\b/, 'insulto'],
  // Odio
  [/\b(heil|viva|arriba|gloria a) hitler\b/, 'odio'],
  [/\b(sucios?|malditos?|asquerosos?) (negros?|indios?|gitanos?|judios?|venezolanos?|gays?|homosexuales|musulmanes|inmigrantes|extranjeros)\b/, 'odio'],
  [/\b(negro|indio|gitano|judio|venezolano|gay|homosexual|musulman|inmigrante|chino) de mierda\b/, 'odio'],
  [/\b(muerte|mueran|que mueran) (a )?(los |las )?(negros|indios|gays|judios|venezolanos|homosexuales|musulmanes|inmigrantes)\b/, 'odio'],
  [/\b(eres|son|sos) (un[ao]? )?(nazi|sudaca|maricon|marica|joto|puto|puta)\b/, 'odio'],
  // Amenazas (el "te voy a destruir / matar en el entreno" de broma entre amigos del gym no está aquí: solo violencia real)
  [/\bte (voy a|vamos a|pienso|quiero|van a|vas a|puedo|podria) (matar|asesinar|violar|apunalar|disparar|secuestrar|golpear|sacar la mierda|partir la (cara|boca|madre)|romper la (cara|boca|madre)|pegar un tiro)\b/, 'amenaza'],
  [/\b(voy a|vamos a) (matarte|asesinarte|violarte|apunalarte|golpearte|secuestrarte)\b/, 'amenaza'],
  [/\b(te mato|te reviento a|te hago pedazos|te quemo vivo)\b/, 'amenaza'],
  [/\b(ojala|espero que|quiero que|deseo que) (te mueras|te mate|te violen|te atropellen|te maten|te de cancer|se muera|se mueran|mueras|mueran)\b/, 'amenaza'],
  [/\b(muerete|matate|suicidate|ahorcate|no mereces vivir|deberias morir|mereces morir)\b/, 'amenaza']
];

// Casos con '*' o '#' dentro de la palabra (p*ta, m#erda, h*jueputa): se reconstruyen con la lista
const ENMASCARADAS = [
  /\bp[*#@_]+ta\b/, /\bp[*#@]+to\b/, /\bm[*#@]+erda\b/, /\bmi[*#@]+rda\b/, /\bh[*#@]+jueputa\b/,
  /\bhijue[*#@]+puta\b/, /\bhijue[*#@]+ta\b/, /\bg[*#@]+norrea\b/, /\bgon[*#@]+rrea\b/,
  /\bp[*#@]+ndejo\b/, /\bpen[*#@]+jo\b/, /\bc[*#@]+br[o0]n\b/, /\bv[*#@]+rga\b/, /\bver[*#@]+a\b/,
  /\bmar[*#@]+ca\b/, /\bm[*#@]+rica\b/, /\bmalpar[*#@]+do\b/, /\bj[*#@]+der\b/
];

// ------------------------------------------------------
// 2. Normalización
// ------------------------------------------------------

const LEET = { '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a', '$': 's', '8': 'b' };

const quitarTildes = (texto) =>
  String(texto || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[​-‏⁠﻿]/g, ''); // caracteres invisibles

// "puuuta" -> "puta", "mierrrda" -> "mierda"
const colapsar = (texto) => texto.replace(/(.)\1+/g, '$1');

// Cambia números y símbolos por letras SOLO dentro de palabras que ya tienen letras
// ("h1jueputa" -> "hijueputa"), sin tocar números sueltos como "100" o "5".
const destransformar = (token) => {
  if (!/[a-z]/.test(token)) return token;
  return token.replace(/[0134578@$]/g, (c) => LEET[c] || c);
};

// Texto -> lista de palabras limpias
const tokenizar = (texto) => {
  // "m!erda": el signo entre letras hace de "i"
  const base = quitarTildes(texto).replace(/ñ/g, 'n').replace(/(?<=[a-z])!(?=[a-z])/g, 'i');
  return (base.match(/[a-z0-9@$]+/g) || []).map(destransformar);
};

// Texto normalizado con palabras separadas por un espacio (para las frases)
const aFrase = (texto) => tokenizar(texto).join(' ');

// ------------------------------------------------------
// 3. Índices (se construyen una sola vez)
// ------------------------------------------------------

const indice = new Map(); // palabra colapsada -> tipo

const registrar = (lista, tipo) => {
  for (const palabra of lista) {
    const limpia = colapsar(quitarTildes(palabra).replace(/ñ/g, 'n'));
    if (limpia && !indice.has(limpia)) indice.set(limpia, tipo);
  }
};

registrar(GROSERIAS, 'groseria');
registrar(INSULTOS, 'insulto');
registrar(ODIO, 'odio');

// Palabras que empiezan con estas raíces siempre son groserías (variantes y diminutivos)
const RAICES = [
  'hijueput', 'hijodeput', 'malparid', 'gonorre', 'pendej', 'mamaguev', 'mamahuev',
  'cabronaz', 'mierd', 'putamadr', 'puteri', 'hijuemad'
].map((r) => colapsar(r));

const esRaiz = (token) => RAICES.some((r) => token.startsWith(r));

// Palabras que parecen groserías pero son normales (se ignoran siempre)
const PERMITIDAS = new Set([
  'computadora', 'computadoras', 'disputa', 'disputas', 'reputacion', 'diputado', 'vergara',
  'imputado', 'imputar', 'deputado', 'putumayo', 'caputo', 'saputo'
]);

// ------------------------------------------------------
// 4. Búsqueda
// ------------------------------------------------------

const evaluarToken = (token) => {
  if (!token || token.length < 2 || PERMITIDAS.has(token)) return null;

  const colapsado = colapsar(token);
  const tipo = indice.get(colapsado) || (esRaiz(colapsado) ? 'groseria' : null);

  if (!tipo) return null;
  if (tipo === 'odio' && ODIO_SOLO_EN_FRASE.has(token)) return null;
  return tipo;
};

// Letras sueltas: "p u t a", "p.u.t.a", "p-u-t-a"
const buscarLetrasSeparadas = (tokens) => {
  let i = 0;

  while (i < tokens.length) {
    if (tokens[i].length !== 1) { i++; continue; }

    let j = i;
    while (j < tokens.length && tokens[j].length === 1) j++;

    if (j - i >= 3) {
      const corrida = tokens.slice(i, j);
      for (let a = 0; a < corrida.length; a++) {
        for (let b = a + 3; b <= corrida.length; b++) {
          const tipo = evaluarToken(corrida.slice(a, b).join(''));
          if (tipo) return tipo;
        }
      }
    }
    i = j;
  }
  return null;
};

/**
 * Analiza un texto.
 * @returns {{ ok: boolean, tipo: ('groseria'|'insulto'|'odio'|'amenaza'|null) }}
 */
export const analizarTexto = (texto) => {
  const original = String(texto ?? '');
  if (!original.trim()) return { ok: true, tipo: null };

  // Palabras sueltas
  const tokens = tokenizar(original);
  for (const token of tokens) {
    const tipo = evaluarToken(token);
    if (tipo) return { ok: false, tipo };
  }

  // Letras separadas
  const separadas = buscarLetrasSeparadas(tokens);
  if (separadas) return { ok: false, tipo: separadas };

  // Con asteriscos o similares: "p*ta"
  const crudo = quitarTildes(original).replace(/ñ/g, 'n');
  if (ENMASCARADAS.some((re) => re.test(crudo))) return { ok: false, tipo: 'groseria' };

  // "coño" se revisa antes de quitar la ñ para no confundirlo con "cono" (cono de tráfico)
  if (/\bco[ñ]os?\b|\bco[ñ]azo\b/.test(String(original).toLowerCase().normalize('NFC'))) {
    return { ok: false, tipo: 'groseria' };
  }

  // Frases
  const frase = aFrase(original);
  for (const [regex, tipo] of FRASES) {
    if (regex.test(frase)) {
      if (tipo === null) return { ok: true, tipo: null };
      return { ok: false, tipo };
    }
  }

  return { ok: true, tipo: null };
};

export const contieneLenguajeInapropiado = (texto) => !analizarTexto(texto).ok;

// Hay un enlace o un correo (para evitar spam en la comunidad)
export const contieneEnlace = (texto) =>
  /(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|co|io|me|ly|xyz|info|ru|tk|gg|app|shop|store)\b|t\.me\/|wa\.me\/|bit\.ly)/i.test(
    String(texto ?? '')
  );

// Mensajes para mostrar al usuario (nunca repiten la palabra)
const MENSAJES = {
  groseria: 'Tu mensaje contiene lenguaje inapropiado. Escríbelo de nuevo de forma respetuosa.',
  insulto: 'Tu mensaje contiene insultos. En FitZone nos tratamos con respeto: reescríbelo, por favor.',
  odio: 'Tu mensaje contiene lenguaje discriminatorio u ofensivo, que no está permitido en FitZone.',
  amenaza: 'Tu mensaje contiene amenazas o violencia, que no están permitidas en FitZone.'
};

export const mensajeModeracion = (tipo) => MENSAJES[tipo] || MENSAJES.groseria;

/**
 * Revisa varios textos de un formulario. Si alguno es inapropiado, responde 422 y
 * devuelve `true` (el controlador debe terminar). Si todo está bien, devuelve `false`.
 */
export const rechazarSiInapropiado = (res, ...textos) => {
  for (const texto of textos) {
    const resultado = analizarTexto(texto);

    if (!resultado.ok) {
      res.status(422).json({
        mensaje: mensajeModeracion(resultado.tipo),
        codigo: 'LENGUAJE_INAPROPIADO'
      });
      return true;
    }
  }
  return false;
};
