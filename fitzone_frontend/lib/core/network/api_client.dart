import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._();

  static const String _tokenKey = 'fitzone_jwt';
  static const String _userIdKey = 'fitzone_user_id';

  static Future<void> saveSession({
    required String token,
    required String userId,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
  }

  static Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove('fitzone_selected_plan');
  }

  static Future<String?> token() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> storedUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> saveSelectedPlan(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fitzone_selected_plan', value);
  }

  static Future<String?> selectedPlan() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('fitzone_selected_plan');
  }

  static Future<dynamic> get(String path, {bool authenticated = false}) async {
    final Map<String, String> headers = await _headers(authenticated);
    return _send(() => http.get(_uri(path), headers: headers));
  }

  static Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final Map<String, String> headers = await _headers(authenticated);
    headers['Content-Type'] = 'application/json';
    return _send(
      () => http.post(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  static Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final Map<String, String> headers = await _headers(authenticated);
    headers['Content-Type'] = 'application/json';
    return _send(
      () => http.put(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  static Uri _uri(String path) {
    final String clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('${ApiConfig.baseUrl}/$clean');
  }

  static Future<dynamic> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final http.Response response = await request().timeout(
        const Duration(seconds: 20),
      );
      dynamic decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = <String, dynamic>{'mensaje': response.body};
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String message = decoded is Map<String, dynamic>
            ? (decoded['mensaje'] ?? decoded['error'] ?? 'Error del servidor').toString()
            : 'Error del servidor';
        throw ApiException(message, statusCode: response.statusCode);
      }

      return decoded;
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        'No se pudo conectar con FitZone. Verifica que el backend esté ejecutándose.',
      );
    }
  }

  static Future<Map<String, String>> _headers(bool authenticated) async {
    final String? jwt = authenticated ? await token() : null;
    return <String, String>{
      'Accept': 'application/json',
      if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
    };
  }
}
