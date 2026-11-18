import User from '../models/User.js';
import Group from '../models/Group.js';
import Coach from '../models/Coach.js';
import Subscription from '../models/Subscription.js';
import Appointment from '../models/Appointment.js';
import Notification from '../models/Notification.js';
import WorkoutSession from '../models/WorkoutSession.js';
import SupportTicket from '../models/SupportTicket.js';
import PhysicalCondition from '../models/PhysicalCondition.js';
import PhysicalMeasurement from '../models/PhysicalMeasurement.js';
import SleepQuality from '../models/SleepQuality.js';
import Motivation from '../models/Motivation.js';
import TrainingFrequency from '../models/TrainingFrequency.js';
import TrainingParameter from '../models/TrainingParameter.js';
import TrainingPeriod from '../models/TrainingPeriod.js';
import DietaryControl from '../models/DietaryControl.js';
import RevokedAccount from '../models/RevokedAccount.js';
import CoachChangeRequest from '../models/CoachChangeRequest.js';
import Post from '../models/Post.js';
import { borrarImagenCloudinary } from '../utils/cloudinary.js';

// ======================================================
// BORRAR UNA CUENTA Y SUS DATOS
//
// Lo usan tanto el admin (eliminarCuenta) como la propia persona desde Ajustes
// (eliminarMiCuenta). Los pagos se conservan por contabilidad y el historial de
// cambios también. No queda ningún bloqueo: se puede volver a registrar con el mismo correo.
// ======================================================

export const eliminarCuentaYDatos = async (usuario) => {
  const id = usuario._id;
  const email = String(usuario.email).toLowerCase().trim();

  await Promise.all([
    PhysicalCondition.deleteMany({ usuarioId: id }),
    PhysicalMeasurement.deleteMany({ usuarioId: id }),
    SleepQuality.deleteMany({ usuarioId: id }),
    Motivation.deleteMany({ usuarioId: id }),
    TrainingFrequency.deleteMany({ usuarioId: id }),
    TrainingParameter.deleteMany({ usuarioId: id }),
    TrainingPeriod.deleteMany({ usuarioId: id }),
    DietaryControl.deleteMany({ usuarioId: id }),
    WorkoutSession.deleteMany({ usuarioId: id }),
    Notification.deleteMany({ usuarioId: id }),
    SupportTicket.deleteMany({ usuarioId: id }),
    CoachChangeRequest.deleteMany({ usuarioId: id }),
    Post.deleteMany({ usuarioId: id }),
    Post.updateMany({}, { $pull: { likes: id, comentarios: { usuarioId: id } } }),
    Appointment.updateMany({ usuarioId: id, estado: 'confirmada' }, { $set: { estado: 'cancelada' } }),
    Subscription.updateMany({ usuarioId: id, estado: { $in: ['activa', 'pendiente'] } }, { $set: { estado: 'cancelada' } }),
    Group.updateMany({ miembros: id }, { $pull: { miembros: id } }),
    Coach.updateMany({ clientesAsignados: id }, { $pull: { clientesAsignados: id } }),
    // Por si el correo quedó bloqueado por el sistema anterior de revocación
    RevokedAccount.deleteMany({ email })
  ]);

  // La foto de perfil también se borra de Cloudinary (no bloquea si falla)
  await borrarImagenCloudinary(usuario.fotoPerfilId);

  await User.findByIdAndDelete(id);
};
