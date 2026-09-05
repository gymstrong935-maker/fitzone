import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import connectDB from './src/config/db.js';

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

const app = express();
connectDB();

app.use(cors());
app.use(express.json());

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

// Ruta no encontrada (404)
app.use((req, res) => {
  res.status(404).json({ mensaje: 'Ruta no encontrada' });
});

// Manejador de errores global
app.use((err, req, res, next) => {
  console.error('❌ Error no controlado:', err.stack);
  res.status(500).json({ mensaje: 'Error interno del servidor' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`🚀 Servidor corriendo en puerto ${PORT}`));