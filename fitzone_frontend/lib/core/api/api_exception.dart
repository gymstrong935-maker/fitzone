/// Error de la API con un mensaje ya listo para mostrar al usuario.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;

  /// Código HTTP; `null` si ni siquiera hubo respuesta del servidor.
  final int? statusCode;

  /// Código interno del backend (p. ej. `CUENTA_NO_VERIFICADA`).
  final String? code;

  /// `true` si no hubo conexión (sin internet o backend apagado).
  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}