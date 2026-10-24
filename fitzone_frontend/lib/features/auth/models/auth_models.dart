/// Modos de la pantalla de autenticación.
enum AuthMode { login, register, forgot }

/// Usuario devuelto por la pantalla de autenticación.
class AuthUser {
  const AuthUser({required this.email, required this.name});

  final String email;
  final String name;
}