// Corrige los horarios de atención de los entrenadores que quedaron en un formato
// que la app no puede leer (p. ej. "Lunes a viernes 6am-8pm") y los deja como
// "lunes 06:00-12:00".
//
// Primero solo MUESTRA lo que cambiaría:   node src/scripts/normalizarHorarios.js
// Para guardar los cambios:                node src/scripts/normalizarHorarios.js --aplicar
import 'dotenv/config';
import mongoose from 'mongoose';
import Coach from '../models/Coach.js';
import { normalizarDisponibilidad } from '../utils/horarios.js';

const aplicar = process.argv.includes('--aplicar');

await mongoose.connect(process.env.MONGO_URI);

const entrenadores = await Coach.find({}).select('nombre disponibilidad');
let corregidos = 0;
let conProblemas = 0;

for (const c of entrenadores) {
  const actuales = c.disponibilidad || [];
  const { validos, invalidos } = normalizarDisponibilidad(actuales);
  const igual = validos.length === actuales.length && validos.every((v, i) => v === actuales[i]);

  if (invalidos.length) {
    conProblemas++;
    console.warn(`⚠️  ${c.nombre}: no se entienden ${JSON.stringify(invalidos)} (corrígelos a mano en el panel admin)`);
  }

  if (igual || (!validos.length && invalidos.length)) continue;

  console.log(`${aplicar ? '✔' : '→'} ${c.nombre}\n    antes:   ${JSON.stringify(actuales)}\n    después: ${JSON.stringify(validos)}`);

  if (aplicar) {
    // Se conservan los horarios que no se entienden para no borrar información
    await Coach.collection.updateOne({ _id: c._id }, { $set: { disponibilidad: [...validos, ...invalidos] } });
  }
  corregidos++;
}

console.log(`\n${aplicar ? 'Corregidos' : 'Se corregirían'}: ${corregidos}. Con horarios ilegibles: ${conProblemas}.`);
if (!aplicar && corregidos) console.log('Ejecuta de nuevo con --aplicar para guardar.');

await mongoose.disconnect();
