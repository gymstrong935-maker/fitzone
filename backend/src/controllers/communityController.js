import mongoose from 'mongoose';
import Post from '../models/Post.js';
import User from '../models/User.js';
import WorkoutSession from '../models/WorkoutSession.js';
import Notification from '../models/Notification.js';

const MAX_COMENTARIOS_POR_POST = 500;
const LIMITE_POR_DEFECTO = 15;
const LIMITE_MAXIMO = 30;

// ─────────────────────────────────────────────────────────────────────────────
// Ayudas
// ─────────────────────────────────────────────────────────────────────────────

const idValido = (id) => mongoose.isValidObjectId(id);

// "Juan Pérez Gómez" -> "Juan P."  (en la comunidad no se muestra el nombre completo)
const nombreCorto = (nombre) => {
  const partes = String(nombre || '').trim().split(/\s+/).filter(Boolean);
  if (!partes.length) return 'Usuario';
  if (partes.length === 1) return partes[0];
  return `${partes[0]} ${partes[1][0].toUpperCase()}.`;
};

const iniciales = (nombre) => {
  const partes = String(nombre || '').trim().split(/\s+/).filter(Boolean);
  if (!partes.length) return 'U';
  return partes.slice(0, 2).map((p) => p[0].toUpperCase()).join('');
};

const autorPublico = (usuario) => ({
  _id: usuario?._id ?? null,
  nombre: nombreCorto(usuario?.nombre),
  iniciales: iniciales(usuario?.nombre),
  fotoPerfil: usuario?.fotoPerfil || ''
});

const idDe = (valor) => String(valor?._id ?? valor ?? '');

const serializarPost = (p, yo) => ({
  _id: p._id,
  autor: autorPublico(p.usuarioId),
  texto: p.texto || '',
  entrenamiento: p.entrenamiento || null,
  likes: p.likes?.length || 0,
  meGusta: (p.likes || []).some((id) => String(id) === yo),
  comentarios: p.numComentarios || 0,
  fecha: p.createdAt,
  esMio: idDe(p.usuarioId) === yo
});

const tituloDelEntrenamiento = (ejercicios = []) => {
  const grupos = [];
  for (const e of ejercicios) {
    if (e.grupoMuscular && !grupos.includes(e.grupoMuscular)) grupos.push(e.grupoMuscular);
  }
  if (!grupos.length) return 'Entrenamiento';
  const mostrados = grupos.slice(0, 3).join(' · ');
  return grupos.length > 3 ? `${mostrados}…` : mostrados;
};

const avisar = async (usuarioId, mensaje) => {
  try {
    await Notification.create({ usuarioId, tipo: 'sistema', mensaje, leida: false });
  } catch (error) {
    console.error('❌ No se pudo crear la notificación:', error.message);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Publicaciones
// ─────────────────────────────────────────────────────────────────────────────

// GET /api/community?limite=15&antes=<id de la última publicación recibida>
export const listarPosts = async (req, res) => {
  try {
    const yo = req.usuario.id;
    const limite = Math.min(Math.max(parseInt(req.query.limite, 10) || LIMITE_POR_DEFECTO, 1), LIMITE_MAXIMO);

    const filtro = {};
    if (req.query.antes) {
      if (!idValido(req.query.antes)) return res.status(400).json({ mensaje: 'Paginación no válida' });
      filtro._id = { $lt: req.query.antes };
    }

    const posts = await Post
      .find(filtro)
      .sort({ _id: -1 })
      .limit(limite)
      .select('-comentarios')
      .populate('usuarioId', 'nombre fotoPerfil')
      .lean();

    res.json(posts.map((p) => serializarPost(p, yo)));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// POST /api/community   { texto?, entrenamientoId? }
export const crearPost = async (req, res) => {
  try {
    const yo = req.usuario.id;
    const { texto, entrenamientoId } = req.body;

    let entrenamiento;

    if (entrenamientoId) {
      // Solo se puede compartir un entrenamiento propio y ya guardado en el servidor
      const sesion = await WorkoutSession.findOne({ _id: entrenamientoId, usuarioId: yo }).lean();

      if (!sesion) {
        return res.status(404).json({
          mensaje: 'No encontramos ese entrenamiento. Si lo acabas de terminar, espera a que se sincronice.'
        });
      }

      const yaCompartido = await Post.exists({ usuarioId: yo, 'entrenamiento.entrenamientoId': sesion._id });
      if (yaCompartido) {
        return res.status(409).json({ mensaje: 'Ya compartiste este entrenamiento' });
      }

      entrenamiento = {
        entrenamientoId: sesion._id,
        titulo: tituloDelEntrenamiento(sesion.ejercicios),
        fecha: sesion.fecha,
        duracionMinutos: sesion.duracionMinutos || 0,
        calorias: sesion.calorias || 0,
        ejercicios: (sesion.ejercicios || []).slice(0, 30).map((e) => ({
          nombre: e.nombre,
          series: e.series,
          repeticiones: e.repeticiones
        }))
      };
    }

    const post = await Post.create({ usuarioId: yo, texto: texto || '', entrenamiento });

    const completo = await Post
      .findById(post._id)
      .select('-comentarios')
      .populate('usuarioId', 'nombre fotoPerfil')
      .lean();

    res.status(201).json(serializarPost(completo, yo));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// DELETE /api/community/:id   (el autor o un admin)
export const eliminarPost = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Publicación no válida' });

    const filtro = { _id: req.params.id };
    if (req.usuario.rol !== 'admin') filtro.usuarioId = req.usuario.id;

    const post = await Post.findOneAndDelete(filtro);
    if (!post) return res.status(404).json({ mensaje: 'Publicación no encontrada' });

    res.json({ mensaje: 'Publicación eliminada' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// POST /api/community/:id/like   (alterna: si ya le diste me gusta, lo quita)
export const alternarLike = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Publicación no válida' });

    const yo = req.usuario.id;
    const post = await Post.findById(req.params.id).select('likes');
    if (!post) return res.status(404).json({ mensaje: 'Publicación no encontrada' });

    const yaLeGusta = post.likes.some((id) => String(id) === yo);

    const actualizado = await Post
      .findByIdAndUpdate(
        req.params.id,
        yaLeGusta ? { $pull: { likes: yo } } : { $addToSet: { likes: yo } },
        { new: true }
      )
      .select('likes');

    res.json({ meGusta: !yaLeGusta, likes: actualizado?.likes.length ?? 0 });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Comentarios
// ─────────────────────────────────────────────────────────────────────────────

// GET /api/community/:id/comentarios
export const listarComentarios = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Publicación no válida' });

    const yo = req.usuario.id;
    const esAdmin = req.usuario.rol === 'admin';

    const post = await Post
      .findById(req.params.id)
      .select('usuarioId comentarios')
      .populate('comentarios.usuarioId', 'nombre fotoPerfil')
      .lean();

    if (!post) return res.status(404).json({ mensaje: 'Publicación no encontrada' });

    const soyAutorDelPost = idDe(post.usuarioId) === yo;

    res.json(
      (post.comentarios || []).map((c) => {
        const esMio = idDe(c.usuarioId) === yo;
        return {
          _id: c._id,
          autor: autorPublico(c.usuarioId),
          texto: c.texto,
          fecha: c.fecha,
          esMio,
          puedeBorrar: esMio || soyAutorDelPost || esAdmin
        };
      })
    );
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// POST /api/community/:id/comentarios   { texto }
export const crearComentario = async (req, res) => {
  try {
    if (!idValido(req.params.id)) return res.status(400).json({ mensaje: 'Publicación no válida' });

    const yo = req.usuario.id;

    const post = await Post.findOneAndUpdate(
      { _id: req.params.id, numComentarios: { $lt: MAX_COMENTARIOS_POR_POST } },
      { $push: { comentarios: { usuarioId: yo, texto: req.body.texto } }, $inc: { numComentarios: 1 } },
      { new: true }
    ).select('usuarioId comentarios');

    if (!post) {
      const existe = await Post.exists({ _id: req.params.id });
      return existe
        ? res.status(409).json({ mensaje: 'Esta publicación ya no admite más comentarios' })
        : res.status(404).json({ mensaje: 'Publicación no encontrada' });
    }

    const nuevo = post.comentarios[post.comentarios.length - 1];
    const autor = await User.findById(yo).select('nombre fotoPerfil').lean();

    if (idDe(post.usuarioId) !== yo) {
      await avisar(post.usuarioId, `${nombreCorto(autor?.nombre)} comentó tu publicación en la comunidad.`);
    }

    res.status(201).json({
      _id: nuevo._id,
      autor: autorPublico(autor),
      texto: nuevo.texto,
      fecha: nuevo.fecha,
      esMio: true,
      puedeBorrar: true
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// DELETE /api/community/:id/comentarios/:comentarioId
// (quien lo escribió, el autor de la publicación o un admin)
export const eliminarComentario = async (req, res) => {
  try {
    const { id, comentarioId } = req.params;
    if (!idValido(id) || !idValido(comentarioId)) {
      return res.status(400).json({ mensaje: 'Comentario no válido' });
    }

    const yo = req.usuario.id;
    const post = await Post.findById(id).select('usuarioId comentarios');
    if (!post) return res.status(404).json({ mensaje: 'Publicación no encontrada' });

    const comentario = post.comentarios.id(comentarioId);
    if (!comentario) return res.status(404).json({ mensaje: 'Comentario no encontrado' });

    const permitido =
      req.usuario.rol === 'admin' ||
      idDe(comentario.usuarioId) === yo ||
      idDe(post.usuarioId) === yo;

    if (!permitido) return res.status(403).json({ mensaje: 'No puedes borrar este comentario' });

    await Post.updateOne(
      { _id: id },
      { $pull: { comentarios: { _id: comentarioId } }, $inc: { numComentarios: -1 } }
    );

    res.json({ mensaje: 'Comentario eliminado' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
