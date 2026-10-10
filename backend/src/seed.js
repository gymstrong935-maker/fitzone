import dns from 'node:dns';
import 'dotenv/config';
import mongoose from 'mongoose';
import connectDB from './config/db.js';
import Plan from './models/Plan.js';
import Group from './models/Group.js';

// =====================================================
// DNS
// =====================================================
// La red local presenta problemas con las consultas SRV
// que Node utiliza para mongodb+srv.
// Google DNS sí resuelve correctamente el SRV de MongoDB.
dns.setServers(['8.8.8.8', '8.8.4.4']);

const seed = async () => {
try {
console.log('🔄 Conectando a MongoDB para ejecutar seed...');

await connectDB();

console.log('✅ MongoDB conectado. Ejecutando seed...');

// =====================================================
// PLANES
// =====================================================

const planes = [
  {
    nombre: 'Gratuito',
    duracionDias: 3,
    precio: 0,
    esGratuito: true,
    beneficios: [
      'Acceso a zona de fitness',
      '1 rutina básica'
    ]
  },
  {
    nombre: 'Mensual',
    duracionDias: 30,
    precio: 80000,
    esGratuito: false,
    beneficios: [
      'Acceso completo',
      'Entrenador asignado',
      'Rutinas personalizadas'
    ]
  },
  {
    nombre: 'Anual',
    duracionDias: 365,
    precio: 800000,
    esGratuito: false,
    beneficios: [
      'Acceso completo',
      'Entrenador asignado',
      'Rutinas personalizadas',
      'Descuento anual',
      'Evaluación física trimestral'
    ]
  }
];

for (const p of planes) {
  const existePlan = await Plan.findOne({
    nombre: p.nombre
  });

  if (!existePlan) {
    await Plan.create(p);

    console.log(`✅ Plan creado: ${p.nombre}`);
  } else {
    console.log(
      `ℹ️ Ya existía el plan "${p.nombre}", no se duplicó`
    );
  }
}

// =====================================================
// GRUPOS POR NIVEL
// =====================================================

const niveles = [
  {
    nombre: 'Grupo A - Principiantes',
    nivel: 'principiante',
    horario: '18:00 - 19:00'
  },
  {
    nombre: 'Grupo B - Intermedios',
    nivel: 'intermedio',
    horario: '19:00 - 20:00'
  },
  {
    nombre: 'Grupo C - Avanzados',
    nivel: 'avanzado',
    horario: '20:00 - 21:00'
  }
];

for (const g of niveles) {
  const existeGrupo = await Group.findOne({
    nivel: g.nivel
  });

  if (!existeGrupo) {
    await Group.create({
      ...g,
      entrenadorId: null,
      miembros: []
    });

    console.log(`✅ Grupo creado: ${g.nombre}`);
  } else {
    console.log(
      `ℹ️ Ya existía un grupo para nivel "${g.nivel}", no se duplicó`
    );
  }
}

console.log('🌱 Seed completado correctamente');

} catch (error) {
console.error('❌ Error ejecutando seed:', error.message);

process.exitCode = 1;

} finally {
await mongoose.disconnect();

console.log('🔌 Conexión a MongoDB cerrada');

}
};

seed();
