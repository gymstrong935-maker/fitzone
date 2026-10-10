import '../api/api_client.dart';
import 'backend_models.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final BackendUser user;
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Crea la cuenta. El backend envía un código de 6 dígitos al correo.
  Future<BackendUser> register({
    required String nombre,
    required String email,
    required String password,
    required String planId,
    String? metodoPago,
  }) async {
    final dynamic data = await _api.post(
      '/api/users/register',
      body: <String, dynamic>{
        'nombre': nombre,
        'email': email,
        'password': password,
        'planId': planId,
        if (metodoPago != null) 'metodoPago': metodoPago,
      },
    );
    return BackendUser.fromJson(
      (data as Map<String, dynamic>)['usuario'] as Map<String, dynamic>,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final dynamic data = await _api.post(
      '/api/users/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );
    final Map<String, dynamic> map = data as Map<String, dynamic>;
    final String token = map['token'] as String;
    _api.setToken(token);
    return AuthResult(
      token: token,
      user: BackendUser.fromJson(map['usuario'] as Map<String, dynamic>),
    );
  }

  Future<void> verifyAccount({
    required String email,
    required String code,
  }) async {
    await _api.post(
      '/api/users/verificar-cuenta',
      body: <String, dynamic>{'email': email, 'codigo': code},
    );
  }

  Future<void> resendCode(String email) async {
    await _api.post(
      '/api/users/reenviar-codigo',
      body: <String, dynamic>{'email': email},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/api/users/forgot-password',
      body: <String, dynamic>{'email': email},
    );
  }

  Future<BackendUser> fetchUser(String id) async {
    final dynamic data = await _api.get('/api/users/$id');
    return BackendUser.fromJson(data as Map<String, dynamic>);
  }
}