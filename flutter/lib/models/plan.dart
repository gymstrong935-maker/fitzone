class Plan {
  final String id;
  final String nombre;
  final double precio;
  final int duracionDias;
  final List<String> beneficios;
  final bool esGratuito;

  Plan({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.duracionDias,
    required this.beneficios,
    required this.esGratuito,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
      duracionDias: json['duracionDias'] ?? 0,
      beneficios: List<String>.from(
        json['beneficios'] ?? [],
      ),
      esGratuito: json['esGratuito'] ?? false,
    );
  }
}