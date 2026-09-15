import 'api_service.dart';

class AuthService {
  final ApiService apiService = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final respuesta = await apiService.post(
      '/users/login',
      {
        'email': email,
        'password': password,
      },
    );

    return respuesta;
  }
}