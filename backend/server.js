import dns from 'node:dns';
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import connectDB from './src/config/db.js';

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
import { iniciarJobVencimientos } from './src/jobs/verificarVencimientosJob.js';

// =====================================================
// DNS
// =====================================================
// Forzamos DNS públicos porque la red local estaba
// rechazando las consultas SRV utilizadas por MongoDB.
dns.setServers(['8.8.8.8', '8.8.4.4']);

const app = express();

// =====================================================
// MIDDLEWARES
// =====================================================

app.use(cors());
app.use(express.json());

// =====================================================
// RUTAS
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
app.use('/api/chat', chatRoutes);

// =====================================================
// RUTA 404
// =====================================================

app.use((req, res) => {
res.status(404).json({
mensaje: 'Ruta no encontrada'
});
});

// =====================================================
// MANEJADOR GLOBAL DE ERRORES
// =====================================================

app.use((err, req, res, next) => {
console.error('❌ Error no controlado:', err.stack);

res.status(500).json({
mensaje: 'Error interno del servidor'
});
});

// =====================================================
// SERVIDOR
// =====================================================

const PORT = process.env.PORT || 4000;

// =====================================================
// INICIO DE LA APLICACIÓN
// =====================================================

const iniciarServidor = async () => {
try {
console.log('🔄 Conectando a MongoDB...');

await connectDB();

console.log('✅ MongoDB conectado correctamente');

// Iniciar el job solamente después de conectar MongoDB.
iniciarJobVencimientos();

app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
});

} catch (error) {
console.error('❌ No se pudo iniciar el servidor:', error.message);
process.exit(1);
}
};

iniciarServidor();
