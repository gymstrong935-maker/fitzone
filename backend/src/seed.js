import 'dotenv/config';
import mongoose from 'mongoose';
import connectDB from './config/db.js';
import Plan from './models/Plan.js';
import Group from './models/Group.js';
import Coach from './models/Coach.js';

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

  // Entrenadores que usa el onboarding de la app
  const coaches = [
    {
      nombre: 'Ana Martínez', fotoPerfil: 'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=400&h=400&fit=crop', especialidad: ['Hipertrofia y Fuerza'], experiencia: 8,
      certificaciones: ['NSCA-CPT', 'ISSA Bodybuilding', 'Nutrición Deportiva'],
      calificacionPromedio: 4.9, descripcion: 'Especialista en desarrollo muscular y programas de fuerza adaptados a cada nivel.',
      tipoEntrenamiento: 'Personalizado con énfasis en técnica y progresión', precio: 89, precioDescripcion: '/mes',
      servicios: ['Plan de entrenamiento personalizado', 'Asesoría nutricional básica', 'Seguimiento semanal', 'Ajustes mensuales del plan', 'Chat de soporte'], nivel: 'premium'
    },
    {
      nombre: 'Carlos Rodríguez', fotoPerfil: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&h=400&fit=crop', especialidad: ['Recomposición Corporal'], experiencia: 10,
      certificaciones: ['ACE', 'Precision Nutrition Level 2', 'NASM-PES'],
      calificacionPromedio: 4.8, descripcion: 'Experto en transformación física combinando entrenamiento y nutrición estratégica.',
      tipoEntrenamiento: 'Enfoque integral: entrenamiento + nutrición', precio: 129, precioDescripcion: '/mes',
      servicios: ['Plan de entrenamiento avanzado', 'Plan nutricional completo', 'Seguimiento diario', 'Videollamadas semanales', 'Ajustes constantes', 'Soporte 24/7'], nivel: 'elite'
    },
    {
      nombre: 'Laura Sánchez', fotoPerfil: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&h=400&fit=crop', especialidad: ['Resistencia y Atletismo'], experiencia: 7,
      certificaciones: ['ACSM-CPT', 'Running Coach', 'Functional Training'],
      calificacionPromedio: 4.7, descripcion: 'Entrenadora de resistencia cardiovascular y preparación atlética de alto rendimiento.',
      tipoEntrenamiento: 'Entrenamiento funcional y deportivo', precio: 79, precioDescripcion: '/mes',
      servicios: ['Plan de entrenamiento funcional', 'Rutinas de cardio personalizadas', 'Seguimiento quincenal', 'Consejos de recuperación'], nivel: 'premium'
    },
    {
      nombre: 'Miguel Torres', fotoPerfil: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&h=400&fit=crop', especialidad: ['Fuerza para Principiantes'], experiencia: 5,
      certificaciones: ['ISSA-CPT', 'Corrective Exercise', 'TRX Certified'],
      calificacionPromedio: 4.9, descripcion: 'Dedicado a guiar principiantes con bases sólidas de técnica y seguridad.',
      tipoEntrenamiento: 'Progresión gradual con énfasis en fundamentos', precio: 49, precioDescripcion: '/mes',
      servicios: ['Plan básico de entrenamiento', 'Videos de técnica', 'Seguimiento mensual', 'Email de soporte'], nivel: 'standard'
    },
    {
      nombre: 'Diana López', fotoPerfil: 'https://images.unsplash.com/photo-1607962837359-5e7e89f86776?w=400&h=400&fit=crop', especialidad: ['Pérdida de Grasa y Tonificación'], experiencia: 6,
      certificaciones: ['NASM-CPT', 'Weight Management', 'Group Fitness'],
      calificacionPromedio: 4.8, descripcion: 'Especialista en programas de definición muscular y pérdida de grasa sostenible.',
      tipoEntrenamiento: 'Combinación de HIIT y entrenamiento de fuerza', precio: 69, precioDescripcion: '/mes',
      servicios: ['Plan de tonificación', 'Rutinas HIIT', 'Guías de alimentación', 'Seguimiento semanal', 'Motivación constante'], nivel: 'standard'
    }
  ];

  for (const c of coaches) {
    await Coach.findOneAndUpdate({ nombre: c.nombre }, c, { upsert: true, new: true, setDefaultsOnInsert: true });
    console.log(`✅ Entrenador sincronizado: ${c.nombre}`);
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