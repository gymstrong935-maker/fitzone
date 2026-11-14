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

  /// pendiente | activo | rechazado | inactivo | suspendido
  String get estadoCuenta => (raw['estadoCuenta'] ?? 'activo').toString();

  /// Motivo que dejó el equipo al rechazar la cuenta (si hubo).
  String get motivoRechazo => (raw['motivoRechazo'] ?? '').toString();

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

/// Pago del usuario (plan o diferencia por cambio de entrenador).
class BackendPayment {
  const BackendPayment({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.metodoPago,
    required this.estado,
    this.comprobanteUrl,
  });

  factory BackendPayment.fromJson(Map<String, dynamic> json) {
    return BackendPayment(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      tipo: (json['tipo'] as String?) ?? 'suscripcion',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      metodoPago: (json['metodoPago'] as String?) ?? 'Sin definir',
      estado: (json['estado'] as String?) ?? 'pendiente',
      comprobanteUrl: json['comprobanteUrl'] as String?,
    );
  }

  final String id;

  /// `suscripcion` o `cambio_entrenador`.
  final String tipo;
  final double monto;

  /// `Efectivo`, `Pago digital` o `Sin definir` (aún no eligió).
  final String metodoPago;
  final String estado;
  final String? comprobanteUrl;

  bool get isPending => estado == 'pendiente';
  bool get needsMethod => isPending && metodoPago == 'Sin definir';
}

/// Solicitud de cambio de entrenador.
class CoachChange {
  const CoachChange({
    required this.id,
    required this.estado,
    required this.currentName,
    required this.newName,
    required this.newId,
    required this.priceCurrent,
    required this.priceNew,
    required this.difference,
    this.payment,
    this.rejectionReason,
  });

  factory CoachChange.fromJson(Map<String, dynamic> json) {
    String nameOf(Object? v) => v is Map ? (v['nombre'] as String? ?? '') : '';
    String idOf(Object? v) =>
        v is Map ? (v['_id'] ?? '').toString() : (v ?? '').toString();
    final Object? pago = json['pagoId'];

    return CoachChange(
      id: (json['_id'] ?? '').toString(),
      estado: (json['estado'] as String?) ?? 'pendiente',
      currentName: nameOf(json['entrenadorActualId']),
      newName: nameOf(json['entrenadorNuevoId']),
      newId: idOf(json['entrenadorNuevoId']),
      priceCurrent: (json['precioActual'] as num?)?.toDouble() ?? 0,
      priceNew: (json['precioNuevo'] as num?)?.toDouble() ?? 0,
      difference: (json['diferencia'] as num?)?.toDouble() ?? 0,
      payment: pago is Map<String, dynamic> ? BackendPayment.fromJson(pago) : null,
      rejectionReason: json['motivoRechazo'] as String?,
    );
  }

  final String id;

  /// `pendiente_pago`, `pendiente`, `aprobada`, `rechazada` o `cancelada`.
  final String estado;
  final String currentName;
  final String newName;
  final String newId;
  final double priceCurrent;
  final double priceNew;
  final double difference;
  final BackendPayment? payment;
  final String? rejectionReason;

  bool get isOpen => estado == 'pendiente_pago' || estado == 'pendiente';
  bool get needsPayment => estado == 'pendiente_pago';
}
