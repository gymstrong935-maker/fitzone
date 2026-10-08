import mongoose from 'mongoose';

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);

    console.log('✅ MongoDB conectado correctamente a la DataBase');
  } catch (error) {
    console.error('❌ Error al conectar MongoDB:', error.message);

    // Lanzamos el error para que server.js
    // decida cómo manejar el fallo de arranque.
    throw error;
  }
};

export default connectDB;