/// Plan tal como lo devuelve el backend.
class BackendPlan {
  const BackendPlan({
    required this.id,
    required this.nombre,
    required this.duracionDias,
    required this.precio,
    required this.esGratuito,
    required this.beneficios,
  });

  final String id;
  final String nombre;
  final int duracionDias;
  final double precio;
  final bool esGratuito;
  final List<String> beneficios;

  factory BackendPlan.fromJson(Map<String, dynamic> json) {
    final Object? rawBenefits = json['beneficios'];
    return BackendPlan(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      duracionDias: (json['duracionDias'] as num?)?.toInt() ?? 0,
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      esGratuito: json['esGratuito'] == true,
      beneficios: rawBenefits is List
          ? <String>[for (final Object? b in rawBenefits) b.toString()]
          : const <String>[],
    );
  }
}

/// Usuario tal como lo devuelve el backend.
class BackendUser {
  const BackendUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.cuentaVerificada,
    required this.fechaRegistro,
    required this.planActual,
    required this.raw,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool cuentaVerificada;
  final DateTime fechaRegistro;

  /// Id (en el backend) del plan actual.
  final String? planActual;

  /// JSON original (se guarda para recordar la sesión).
  final Map<String, dynamic> raw;

  factory BackendUser.fromJson(Map<String, dynamic> json) {
    final Object? plan = json['planActual'];
    return BackendUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      rol: (json['rol'] ?? 'cliente').toString(),
      cuentaVerificada: json['cuentaVerificada'] != false,
      fechaRegistro:
          DateTime.tryParse((json['fechaRegistro'] ?? '').toString())
                  ?.toLocal() ??
              DateTime.now(),
      planActual: plan is Map<String, dynamic>
          ? (plan['_id'] ?? '').toString()
          : plan?.toString(),
      raw: json,
    );
  }
}

/// Suscripción tal como la devuelve el backend.
class BackendSubscription {
  const BackendSubscription({
    required this.id,
    required this.planId,
    required this.estado,
    required this.fechaFin,
  });

  final String id;
  final String? planId;

  /// pendiente | activa | vencida | cancelada | rechazada
  final String estado;
  final DateTime? fechaFin;

  bool get isActive =>
      estado == 'activa' && (fechaFin == null || fechaFin!.isAfter(DateTime.now()));

  factory BackendSubscription.fromJson(Map<String, dynamic> json) {
    final Object? plan = json['planId'];
    return BackendSubscription(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      planId: plan is Map<String, dynamic>
          ? (plan['_id'] ?? '').toString()
          : plan?.toString(),
      estado: (json['estado'] ?? '').toString(),
      fechaFin: DateTime.tryParse((json['fechaFin'] ?? '').toString())?.toLocal(),
    );
  }
}