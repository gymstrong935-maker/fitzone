import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP del backend: agrega el token, convierte errores en
/// [ApiException] y avisa cuando el token deja de servir.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  /// Se ejecuta cuando el servidor rechaza el token (vencido o inválido).
  void Function()? onSessionExpired;

  String? get token => _token;

  void setToken(String? token) => _token = token;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final String? encoded = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.timeout);
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.timeout);
        default:
          response =
              await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
      }
    } on TimeoutException {
      throw const ApiException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw ApiException(
        'No se pudo conectar con el servidor (${ApiConfig.baseUrl}). '
        '¿Está encendido el backend?',
      );
    }

    dynamic data;
    if (response.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    final int status = response.statusCode;
    if (status >= 200 && status < 300) return data;

    final ApiException error = _toException(status, data);

    final bool tokenRejected = _token != null &&
        (status == 401 ||
            (status == 403 && error.message.toLowerCase().contains('token')));
    if (tokenRejected) onSessionExpired?.call();

    throw error;
  }

  ApiException _toException(int status, dynamic data) {
    String message = 'Error del servidor ($status)';
    String? code;

    if (data is Map<String, dynamic>) {
      final Object? m = data['mensaje'] ?? data['error'];
      if (m is String && m.isNotEmpty) message = m;

      final Object? errores = data['errores'];
      if (errores is List && errores.isNotEmpty) {
        message = errores.map((Object? e) => e.toString()).join('\n');
      }

      final Object? c = data['codigo'];
      if (c is String) code = c;
    }

    return ApiException(message, statusCode: status, code: code);
  }
}