import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService.instance;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        '/users/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;

      final token = data['token']?.toString();

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token);

        _api.setToken(token);
      }

      UserModel? user;

      if (data['usuario'] != null) {
        user = UserModel.fromJson(
          Map<String, dynamic>.from(data['usuario']),
        );

        final prefs = await SharedPreferences.getInstance();

        if (user.id != null) {
          await prefs.setString('user_id', user.id!);
        }
      }

      return {
        'success': true,
        'message': data['mensaje'] ?? 'Sesión iniciada',
        'user': user,
        'token': token,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    try {
      final response = await _api.dio.post(
        '/users/register',
        data: {
          'nombre': nombre,
          'email': email,
          'password': password,
          if (telefono != null && telefono.isNotEmpty)
            'telefono': telefono,
        },
      );

      final data = response.data as Map<String, dynamic>;

      return {
        'success': true,
        'message': data['mensaje'] ?? 'Usuario registrado',
        'user': data['usuario'] != null
            ? UserModel.fromJson(
                Map<String, dynamic>.from(data['usuario']),
              )
            : null,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> verifyAccount({
    required String email,
    required String codigo,
  }) async {
    try {
      final response = await _api.dio.post(
        '/users/verificar-cuenta',
        data: {
          'email': email,
          'codigo': codigo,
        },
      );

      return {
        'success': true,
        'message': response.data['mensaje'] ?? 'Cuenta verificada',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    try {
      final response = await _api.dio.post(
        '/users/reenviar-codigo',
        data: {
          'email': email,
        },
      );

      return {
        'success': true,
        'message': response.data['mensaje'] ?? 'Código reenviado',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _api.dio.post(
        '/users/forgot-password',
        data: {
          'email': email,
        },
      );

      return {
        'success': true,
        'message': response.data['mensaje'] ??
            'Se enviaron las instrucciones.',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user_id');

    _api.removeToken();
  }

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return false;
    }

    _api.setToken(token);

    return true;
  }

  Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('user_id');
  }
}