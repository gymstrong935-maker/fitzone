import 'dotenv/config';
import mongoose from 'mongoose';
import connectDB from './config/db.js';
import Plan from './models/Plan.js';
import Group from './models/Group.js';

const seed = async () => {
  await connectDB();

  // Planes
  const planes = [
    {
      nombre: 'Gratuito',
      duracionDias: 3,
      precio: 0,
      esGratuito: true,
      beneficios: ['Acceso a zona de fitness', '1 rutina básica']
    },
    {
      nombre: 'Mensual',
      duracionDias: 30,
      precio: 80000,
      esGratuito: false,
      beneficios: ['Acceso completo', 'Entrenador asignado', 'Rutinas personalizadas']
    },
    {
      nombre: 'Anual',
      duracionDias: 365,
      precio: 800000,
      esGratuito: false,
      beneficios: ['Acceso completo', 'Entrenador asignado', 'Rutinas personalizadas', 'Descuento anual', 'Evaluación física trimestral']
    }
  ];

  for (const p of planes) {
    const existePlan = await Plan.findOne({ nombre: p.nombre });
    if (!existePlan) {
      await Plan.create(p);
      console.log(`✅ Plan creado: ${p.nombre}`);
    } else {
      console.log(`ℹ️ Ya existía el plan "${p.nombre}", no se duplicó`);
    }
  }

  // Grupos por nivel
  const niveles = [
    { nombre: 'Grupo A - Principiantes', nivel: 'principiante', horario: '18:00 - 19:00' },
    { nombre: 'Grupo B - Intermedios', nivel: 'intermedio', horario: '19:00 - 20:00' },
    { nombre: 'Grupo C - Avanzados', nivel: 'avanzado', horario: '20:00 - 21:00' }
  ];

  for (const g of niveles) {
    const existeGrupo = await Group.findOne({ nivel: g.nivel });
    if (!existeGrupo) {
      await Group.create({ ...g, entrenadorId: null, miembros: [] });
      console.log(`✅ Grupo creado: ${g.nombre}`);
    } else {
      console.log(`ℹ️ Ya existía un grupo para nivel "${g.nivel}", no se duplicó`);
    }
  }

  console.log('🌱 Seed completado');
  await mongoose.disconnect();
  process.exit(0);
};

seed();