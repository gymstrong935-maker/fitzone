import mongoose from 'mongoose';

const connectDB = async () => {
try {
await mongoose.connect(process.env.MONGO_URI);

console.log('✅ MongoDB conectado correctamente a la DataBase');

} catch (error) {
console.error('❌ Error al conectar MongoDB:', error.message);

throw error;

}
};

export default connectDB;
