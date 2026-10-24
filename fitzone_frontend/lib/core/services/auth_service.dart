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
  /// El método de pago ya no se pide aquí: se elige cuando el equipo aprueba la cuenta.
  Future<BackendUser> register({
    required String nombre,
    required String email,
    required String password,
    required String planId,
  }) async {
    final dynamic data = await _api.post(
      '/api/users/register',
      body: <String, dynamic>{
        'nombre': nombre,
        'email': email,
        'password': password,
        'planId': planId,
      },
    );
    return BackendUser.fromJson(
      (data as Map<String, dynamic>)['usuario'] as Map<String, dynamic>,
    );
  }

  /// Inicia sesión con correo y contraseña. Si se indica [planId], quien ya
  /// tiene cuenta solo entra con el plan con el que se registró.
  Future<AuthResult> login({
    required String email,
    required String password,
    String? planId,
  }) async {
    final dynamic data = await _api.post(
      '/api/users/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
        if (planId != null) 'planId': planId,
      },
    );
    return _result(data);
  }

  /// Inicia sesión (o crea la cuenta) con el ID token que entrega Google.
  ///
  /// [planId] es el plan elegido en pantalla. Es obligatorio para crear una
  /// cuenta nueva; si la persona ya tiene cuenta, el servidor comprueba que
  /// sea su mismo plan mientras su inscripción siga vigente.
  Future<AuthResult> loginWithGoogle(String idToken, {String? planId}) async {
    final dynamic data = await _api.post(
      '/api/users/google',
      body: <String, dynamic>{
        'idToken': idToken,
        if (planId != null) 'planId': planId,
      },
    );
    return _result(data);
  }

  AuthResult _result(dynamic data) {
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

  /// Envía un código de 6 dígitos al correo para restablecer la contraseña.
  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/api/users/forgot-password',
      body: <String, dynamic>{'email': email},
    );
  }

  /// Cambia la contraseña con el código recibido por correo.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _api.post(
      '/api/users/reset-password',
      body: <String, dynamic>{
        'email': email,
        'codigo': code,
        'password': password,
      },
    );
  }

  Future<BackendUser> fetchUser(String id) async {
    final dynamic data = await _api.get('/api/users/$id');
    return BackendUser.fromJson(data as Map<String, dynamic>);
  }
}
