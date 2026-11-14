import dns from 'node:dns';
import 'dotenv/config';
import express from 'express';
import cors from 'cors';

import connectDB from './src/config/db.js';

// Rutas
import chatRoutes from './src/routes/chatRoutes.js';
import userRoutes from './src/routes/userRoutes.js';
import planRoutes from './src/routes/planRoutes.js';
import coachRoutes from './src/routes/coachRoutes.js';
import groupRoutes from './src/routes/groupRoutes.js';
import paymentRoutes from './src/routes/paymentRoutes.js';
import subscriptionRoutes from './src/routes/subscriptionRoutes.js';
import notificationRoutes from './src/routes/notificationRoutes.js';
import physicalConditionRoutes from './src/routes/physicalConditionRoutes.js';
import physicalMeasurementRoutes from './src/routes/physicalMeasurementRoutes.js';
import sleepQualityRoutes from './src/routes/sleepQualityRoutes.js';
import motivationRoutes from './src/routes/motivationRoutes.js';
import trainingFrequencyRoutes from './src/routes/trainingFrequencyRoutes.js';
import trainingParameterRoutes from './src/routes/trainingParameterRoutes.js';
import trainingPeriodRoutes from './src/routes/trainingPeriodRoutes.js';
import dietaryControlRoutes from './src/routes/dietaryControlRoutes.js';
import appointmentRoutes from './src/routes/appointmentRoutes.js';
import workoutRoutes from './src/routes/workoutRoutes.js';
import adminRoutes from './src/routes/adminRoutes.js';
import supportRoutes from './src/routes/supportRoutes.js';

import { iniciarJobVencimientos } from './src/jobs/verificarVencimientosJob.js';

// =====================================================
// VALIDACIÓN DEL ENTORNO
// =====================================================

const faltantes = ['MONGO_URI', 'JWT_SECRET', 'GOOGLE_SERVER_CLIENT_ID'].filter(
  (k) => !String(process.env[k] || '').trim()
);

if (faltantes.length) {
  console.error(`❌ Faltan variables en .env: ${faltantes.join(', ')}`);
  process.exit(1);
}

if (process.env.JWT_SECRET.trim().startsWith('GOCSPX') || process.env.JWT_SECRET.trim().length < 32) {
  console.warn(
    '⚠️  JWT_SECRET es débil o parece el client secret de Google. ' +
    'Genera una cadena aleatoria de 64+ caracteres (ver .env.example).'
  );
}

// =====================================================
// CONFIGURACIÓN
// =====================================================

dns.setServers(['8.8.8.8', '8.8.4.4']);

const app = express();
app.disable('x-powered-by');

// Detrás del proxy de Render/Heroku/Nginx la IP real viene en X-Forwarded-For.
// Sin esto, el límite de intentos cuenta TODAS las peticiones como una sola IP
// y termina bloqueando a todos los usuarios.
app.set('trust proxy', 1);

process.on('unhandledRejection', (motivo) => {
  console.error('⚠️ Promesa rechazada sin manejar:', motivo);
});

app.use(cors());
app.use(express.json({ limit: '1mb' }));

// =====================================================
// RUTAS PÚBLICAS
// =====================================================

app.get('/', (req, res) => {
  res.status(200).send('Bienvenido a nuestro servidor FitZone');
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Servidor FitZone funcionando correctamente',
  });
});

// =====================================================
// RUTAS DE LA API
// =====================================================

app.use('/api/users', userRoutes);
app.use('/api/plans', planRoutes);
app.use('/api/coaches', coachRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/physical-conditions', physicalConditionRoutes);
app.use('/api/physical-measurements', physicalMeasurementRoutes);
app.use('/api/sleep-quality', sleepQualityRoutes);
app.use('/api/motivation', motivationRoutes);
app.use('/api/training-frequency', trainingFrequencyRoutes);
app.use('/api/training-parameters', trainingParameterRoutes);
app.use('/api/training-periods', trainingPeriodRoutes);
app.use('/api/dietary-control', dietaryControlRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/workouts', workoutRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/chat', chatRoutes);

// =====================================================
// RUTA 404
// Debe estar después de todas las rutas.
// =====================================================

app.use((req, res) => {
  res.status(404).json({
    mensaje: 'Ruta no encontrada',
    ruta: req.originalUrl,
  });
});

// =====================================================
// MANEJADOR GLOBAL DE ERRORES
// Debe ser el último middleware.
// =====================================================

app.use((err, req, res, next) => {
  console.error('Error no controlado:', err.stack || err.message);

  if (res.headersSent) {
    return next(err);
  }

  res.status(500).json({
    mensaje: 'Error interno del servidor',
  });
});

// =====================================================
// INICIO DEL SERVIDOR
// =====================================================

const PORT = process.env.PORT || 4000;

const iniciarServidor = async () => {
  try {
    console.log('Conectando a MongoDB...');

    await connectDB();

    console.log('MongoDB conectado correctamente');

    iniciarJobVencimientos();

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Servidor FitZone corriendo en puerto ${PORT}`);
    });
  } catch (error) {
    console.error('No se pudo iniciar el servidor:', error);
    process.exit(1);
  }
};

iniciarServidor();
