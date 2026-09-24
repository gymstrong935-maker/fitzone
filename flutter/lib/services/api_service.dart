import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeToken() {
    dio.options.headers.remove('Authorization');
  }

  String getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        return data['mensaje']?.toString() ??
            data['error']?.toString() ??
            'Ha ocurrido un error.';
      }

      return error.message ?? 'Error de conexión.';
    }

    return 'Ha ocurrido un error inesperado.';
  }
}