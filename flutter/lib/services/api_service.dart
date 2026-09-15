import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // Para Android Emulator
  static const String baseUrl =
      'http://10.0.2.2:4000/api';

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      Map<String, dynamic> respuesta = {};

      if (response.body.isNotEmpty) {
        try {
          respuesta = jsonDecode(response.body);
        } catch (e) {
          respuesta = {
            'mensaje': response.body,
          };
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return respuesta;
      }

      throw ApiException(
        respuesta['mensaje']?.toString() ??
            respuesta['error']?.toString() ??
            'Error en el servidor',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }

      throw Exception(
        'No se pudo conectar con el servidor',
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(
    this.message,
    this.statusCode,
  );

  @override
  String toString() {
    return message;
  }
}