import '../api/api_client.dart';
import 'backend_models.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final BackendUser user;
}

/// FitZone solo permite ingresar con Google (registro e inicio de sesión
/// comparten el mismo endpoint).
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

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
    final Map<String, dynamic> map = data as Map<String, dynamic>;
    final String token = map['token'] as String;
    _api.setToken(token);
    return AuthResult(
      token: token,
      user: BackendUser.fromJson(map['usuario'] as Map<String, dynamic>),
    );
  }

  Future<BackendUser> fetchUser(String id) async {
    final dynamic data = await _api.get('/api/users/$id');
    return BackendUser.fromJson(data as Map<String, dynamic>);
  }
}
