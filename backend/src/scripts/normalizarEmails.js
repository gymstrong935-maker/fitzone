// Pasa a minúsculas los correos que se guardaron con mayúsculas.
// Uso (una sola vez):  node src/scripts/normalizarEmails.js
import 'dotenv/config';
import mongoose from 'mongoose';
import User from '../models/User.js';

await mongoose.connect(process.env.MONGO_URI);

const usuarios = await User.find({}).select('email');
let cambiados = 0;
let conflictos = 0;

for (const u of usuarios) {
  const limpio = String(u.email || '').trim().toLowerCase();
  if (!limpio || limpio === u.email) continue;

  const otro = await User.findOne({ email: limpio, _id: { $ne: u._id } }).select('_id');
  if (otro) {
    console.warn(`⚠️ Conflicto: ${u.email} y ${limpio} existen como cuentas distintas. Revísalo a mano.`);
    conflictos++;
    continue;
  }

  await User.collection.updateOne({ _id: u._id }, { $set: { email: limpio } });
  console.log(`✔ ${u.email} → ${limpio}`);
  cambiados++;
}

console.log(`Listo. Corregidos: ${cambiados}. Conflictos: ${conflictos}.`);
await mongoose.disconnect();
