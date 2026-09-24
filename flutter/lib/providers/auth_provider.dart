import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await _authService.restoreSession();

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _user = result['user'];
      _isAuthenticated = true;
      notifyListeners();

      return null;
    }

    notifyListeners();

    return result['message']?.toString() ??
        'No fue posible iniciar sesión.';
  }

  Future<String?> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.register(
      nombre: nombre,
      email: email,
      password: password,
      telefono: telefono,
    );

    _isLoading = false;
    notifyListeners();

    if (result['success'] == true) {
      return null;
    }

    return result['message']?.toString() ??
        'No fue posible registrar el usuario.';
  }

  Future<String?> verifyAccount({
    required String email,
    required String codigo,
  }) async {
    final result = await _authService.verifyAccount(
      email: email,
      codigo: codigo,
    );

    if (result['success'] == true) {
      return null;
    }

    return result['message']?.toString();
  }

  Future<String?> resendCode({
    required String email,
  }) async {
    final result = await _authService.resendCode(
      email: email,
    );

    if (result['success'] == true) {
      return null;
    }

    return result['message']?.toString();
  }

  Future<String?> forgotPassword({
    required String email,
  }) async {
    final result = await _authService.forgotPassword(
      email: email,
    );

    if (result['success'] == true) {
      return null;
    }

    return result['message']?.toString();
  }

  Future<void> logout() async {
    await _authService.logout();

    _user = null;
    _isAuthenticated = false;

    notifyListeners();
  }
}