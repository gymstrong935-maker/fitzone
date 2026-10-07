import User from '../models/User.js';
import Coach from '../models/Coach.js';
import PhysicalCondition from '../models/PhysicalCondition.js';
import PhysicalMeasurement from '../models/PhysicalMeasurement.js';
import Motivation from '../models/Motivation.js';
import TrainingFrequency from '../models/TrainingFrequency.js';
import TrainingPeriod from '../models/TrainingPeriod.js';
import SleepQuality from '../models/SleepQuality.js';
import Group from '../models/Group.js';

const EXPERIENCE_TO_LEVEL = {
  beginner: 'principiante',
  intermediate: 'intermedio',
  advanced: 'avanzado'
};

const SLEEP_TO_NUMBER = {
  poor: 1,
  fair: 2,
  good: 4,
  excellent: 5
};

export const guardarOnboarding = async (req, res) => {
  try {
    const usuarioId = req.usuario.id;
    const { personal, mediciones, objetivo, nivelExperiencia, habitos, coachId, coachNombre } = req.body;

    const usuario = await User.findById(usuarioId);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    let coach = null;
    if (coachId) coach = await Coach.findById(coachId);
    if (!coach && coachNombre) coach = await Coach.findOne({ nombre: coachNombre });

    if (coach) {
      if (usuario.entrenadorAsignado && usuario.entrenadorAsignado.toString() !== coach._id.toString()) {
        await Coach.findByIdAndUpdate(usuario.entrenadorAsignado, { $pull: { clientesAsignados: usuario._id } });
      }
      if (!coach.clientesAsignados.some((id) => id.toString() === usuario._id.toString())) {
        coach.clientesAsignados.push(usuario._id);
        await coach.save();
      }
      usuario.entrenadorAsignado = coach._id;
    }

    usuario.edad = personal.edad;
    usuario.genero = personal.genero;
    usuario.peso = personal.peso;
    usuario.unidadPeso = personal.unidadPeso;
    usuario.alturaCm = personal.alturaCm;
    usuario.condicionFisica = personal.condicionFisica;
    usuario.nivelExperiencia = nivelExperiencia;
    usuario.condicionesMedicas = personal.condicionesMedicas || '';
    await usuario.save();

    const nivel = EXPERIENCE_TO_LEVEL[nivelExperiencia];

    const condicion = await PhysicalCondition.findOneAndUpdate(
      { usuarioId },
      {
        usuarioId,
        nivel,
        nivelExperiencia,
        condicionFisica: personal.condicionFisica,
        lesiones: personal.condicionesMedicas ? [personal.condicionesMedicas] : [],
        restricciones: [],
        observacionesMedicas: personal.condicionesMedicas || ''
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    const medidas = await PhysicalMeasurement.findOneAndUpdate(
      { usuarioId },
      {
        usuarioId,
        fecha: new Date(),
        peso: mediciones.peso,
        altura: mediciones.altura,
        imc: mediciones.imc ?? Number((mediciones.peso / (mediciones.altura * mediciones.altura)).toFixed(2)),
        porcentajeGrasa: mediciones.porcentajeGrasa,
        medidas: mediciones.medidas,
        pliegues: mediciones.pliegues
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    await Motivation.findOneAndUpdate(
      { usuarioId },
      {
        usuarioId,
        fecha: new Date(),
        nivelMotivacion: personal.motivacion,
        nivelEstres: personal.estres,
        nivelEnergia: personal.energia,
        comentario: 'Datos iniciales del onboarding'
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    await TrainingFrequency.findOneAndUpdate(
      { usuarioId },
      {
        usuarioId,
        diasPorSemana: habitos.frecuencia,
        diasPreferidos: habitos.disponibilidad,
        horarioPreferido: '',
        duracionMinutos: habitos.duracionMinutos,
        nivelActividad: habitos.nivelActividad,
        disponibilidad: habitos.disponibilidad
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    await SleepQuality.findOneAndUpdate(
      { usuarioId },
      {
        usuarioId,
        fecha: new Date(),
        horasDormidas: habitos.horasSueno,
        calidadPercibida: SLEEP_TO_NUMBER[habitos.calidadSueno],
        calidadTexto: habitos.calidadSueno,
        interrupciones: 0
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    const ahora = new Date();
    const fin = new Date(ahora);
    fin.setDate(fin.getDate() + 7);

    await TrainingPeriod.findOneAndUpdate(
      { usuarioId },
      {
        usuarioId,
        duracionSemanas: 1,
        fechaInicio: ahora,
        fechaFin: fin,
        objetivo,
        nivelExperiencia
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    let grupoAsignado = null;
    if (nivel) {
      const grupo = await Group.findOne({ nivel });
      if (grupo) {
        if (!grupo.miembros.some((id) => id.toString() === usuario._id.toString())) {
          grupo.miembros.push(usuario._id);
          await grupo.save();
        }
        grupoAsignado = grupo.nombre;
      }
    }

    return res.status(200).json({
      completado: true,
      mensaje: 'Onboarding guardado correctamente',
      usuario,
      coachNombre: coach?.nombre ?? null,
      grupoAsignado,
      registros: {
        condicionId: condicion._id,
        medicionId: medidas._id
      }
    });
  } catch (error) {
    console.error('❌ Error guardando onboarding:', error);
    return res.status(500).json({ mensaje: 'No se pudo guardar el onboarding', error: error.message });
  }
};

export const obtenerOnboarding = async (req, res) => {
  try {
    const usuarioId = req.usuario.id;
    const [usuario, condicion, medicion, motivacion, frecuencia, sueno, periodo] = await Promise.all([
      User.findById(usuarioId).populate('entrenadorAsignado'),
      PhysicalCondition.findOne({ usuarioId }),
      PhysicalMeasurement.findOne({ usuarioId }).sort({ fecha: -1 }),
      Motivation.findOne({ usuarioId }).sort({ fecha: -1 }),
      TrainingFrequency.findOne({ usuarioId }),
      SleepQuality.findOne({ usuarioId }).sort({ fecha: -1 }),
      TrainingPeriod.findOne({ usuarioId }).sort({ fechaInicio: -1 })
    ]);

    const completado = Boolean(condicion && medicion && frecuencia && sueno && periodo);
    res.json({
      completado,
      coachNombre: usuario?.entrenadorAsignado?.nombre ?? null,
      condicion,
      medicion,
      motivacion,
      frecuencia,
      sueno,
      periodo
    });
  } catch (error) {
    res.status(500).json({ mensaje: 'No se pudo obtener el onboarding', error: error.message });
  }
};
