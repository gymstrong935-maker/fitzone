const validar = (schema) => (req, res, next) => {
  const resultado = schema.safeParse(req.body);
  if (!resultado.success) {
    const errores = (resultado.error.issues || resultado.error.errors || [])
      .map(e => e.message);
    return res.status(400).json({ mensaje: 'Datos inválidos', errores });
  }
  req.body = resultado.data;
  next();
};

export default validar;