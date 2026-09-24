class UserModel {
  final String? id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? rol;
  final bool cuentaVerificada;
  final String? fotoPerfil;

  UserModel({
    this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.rol,
    this.cuentaVerificada = false,
    this.fotoPerfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString(),
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'],
      rol: json['rol'],
      cuentaVerificada: json['cuentaVerificada'] ?? false,
      fotoPerfil: json['fotoPerfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'cuentaVerificada': cuentaVerificada,
      'fotoPerfil': fotoPerfil,
    };
  }
}