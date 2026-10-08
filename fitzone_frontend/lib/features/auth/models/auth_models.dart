/// Modos de la pantalla de autenticación.
enum AuthMode { login, register, forgot }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
}
