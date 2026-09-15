class Trainer {
  final String id;
  final String nombre;
  final String especialidad;
  final double calificacion;
  final int experiencia;
  final String descripcion;
  final String precio;
  final String imagen;
  final List<String> certificaciones;

  Trainer({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.calificacion,
    required this.experiencia,
    required this.descripcion,
    required this.precio,
    required this.imagen,
    required this.certificaciones,
  });
}