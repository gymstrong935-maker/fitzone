import dns from 'node:dns';
import 'dotenv/config';
import mongoose from 'mongoose';
import connectDB from './config/db.js';
import Coach from './models/Coach.js';

// Misma corrección de DNS que usa el seed de planes
dns.setServers(['8.8.8.8', '8.8.4.4']);

const entrenadores = [
  {
    nombre: 'Ana Martínez',
    especialidad: ['Hipertrofia', 'Fuerza'],
    disponibilidad: ['lunes 06:00-12:00', 'miércoles 06:00-12:00', 'viernes 06:00-12:00', 'sábado 08:00-12:00'],
    calificacionPromedio: 4.9,
    experiencia: 8,
    certificaciones: ['NSCA-CPT', 'ISSA Bodybuilding', 'Nutrición Deportiva'],
    descripcion: 'Especialista en desarrollo muscular y programas de fuerza adaptados a cada nivel.',
    tipoEntrenamiento: 'Personalizado con énfasis en técnica y progresión',
    precio: 89000,
    servicios: [
      'Plan de entrenamiento personalizado', 'Asesoría nutricional básica',
      'Seguimiento semanal', 'Ajustes mensuales del plan', 'Chat de soporte'
    ],
    nivel: 'premium',
    fotoPerfil: 'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=400&h=400&fit=crop'
  },
  {
    nombre: 'Carlos Rodríguez',
    especialidad: ['Recomposición Corporal'],
    disponibilidad: ['martes 14:00-20:00', 'jueves 14:00-20:00', 'sábado 09:00-13:00'],
    calificacionPromedio: 4.8,
    experiencia: 10,
    certificaciones: ['ACE', 'Precision Nutrition Level 2', 'NASM-PES'],
    descripcion: 'Experto en transformación física combinando entrenamiento y nutrición estratégica.',
    tipoEntrenamiento: 'Enfoque integral: entrenamiento + nutrición',
    precio: 129000,
    servicios: [
      'Plan de entrenamiento avanzado', 'Plan nutricional completo', 'Seguimiento diario',
      'Videollamadas semanales', 'Ajustes constantes', 'Soporte 24/7'
    ],
    nivel: 'elite',
    fotoPerfil: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&h=400&fit=crop'
  },
  {
    nombre: 'Laura Sánchez',
    especialidad: ['Resistencia', 'Atletismo'],
    disponibilidad: ['lunes 16:00-20:00', 'miércoles 16:00-20:00', 'viernes 16:00-20:00'],
    calificacionPromedio: 4.7,
    experiencia: 7,
    certificaciones: ['ACSM-CPT', 'Running Coach', 'Functional Training'],
    descripcion: 'Entrenadora de resistencia cardiovascular y preparación atlética de alto rendimiento.',
    tipoEntrenamiento: 'Entrenamiento funcional y deportivo',
    precio: 79000,
    servicios: [
      'Plan de entrenamiento funcional', 'Rutinas de cardio personalizadas',
      'Seguimiento quincenal', 'Consejos de recuperación'
    ],
    nivel: 'premium',
    fotoPerfil: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&h=400&fit=crop'
  },
  {
    nombre: 'Miguel Torres',
    especialidad: ['Fuerza para Principiantes'],
    disponibilidad: ['lunes 08:00-12:00', 'martes 08:00-12:00', 'jueves 08:00-12:00', 'viernes 08:00-12:00'],
    calificacionPromedio: 4.9,
    experiencia: 5,
    certificaciones: ['ISSA-CPT', 'Corrective Exercise', 'TRX Certified'],
    descripcion: 'Dedicado a guiar principiantes con bases sólidas de técnica y seguridad.',
    tipoEntrenamiento: 'Progresión gradual con énfasis en fundamentos',
    precio: 49000,
    servicios: [
      'Plan básico de entrenamiento', 'Videos de técnica', 'Seguimiento mensual', 'Email de soporte'
    ],
    nivel: 'standard',
    fotoPerfil: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&h=400&fit=crop'
  },
  {
    nombre: 'Diana López',
    especialidad: ['Pérdida de Grasa', 'Tonificación'],
    disponibilidad: ['martes 06:00-10:00', 'jueves 06:00-10:00', 'sábado 08:00-12:00', 'domingo 09:00-12:00'],
    calificacionPromedio: 4.8,
    experiencia: 6,
    certificaciones: ['NASM-CPT', 'Weight Management', 'Group Fitness'],
    descripcion: 'Especialista en programas de definición muscular y pérdida de grasa sostenible.',
    tipoEntrenamiento: 'Combinación de HIIT y entrenamiento de fuerza',
    precio: 69000,
    servicios: [
      'Plan de tonificación', 'Rutinas HIIT', 'Guías de alimentación',
      'Seguimiento semanal', 'Motivación constante'
    ],
    nivel: 'standard',
    fotoPerfil: 'https://images.unsplash.com/photo-1607962837359-5e7e89f86776?w=400&h=400&fit=crop'
  }
];

const seed = async () => {
  try {
    console.log('🔄 Conectando a MongoDB para crear entrenadores...');
    await connectDB();

    for (const entrenador of entrenadores) {
      await Coach.findOneAndUpdate(
        { nombre: entrenador.nombre },
        { $set: entrenador },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
      console.log(`✅ ${entrenador.nombre}`);
    }

    console.log('🎉 Entrenadores listos');
  } catch (error) {
    console.error('❌ Error en el seed de entrenadores:', error);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
};

seed();