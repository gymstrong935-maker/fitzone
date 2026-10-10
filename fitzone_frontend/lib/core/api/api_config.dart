import 'package:flutter/foundation.dart';

/// Dirección del backend.
///
/// - Chrome / Windows / iOS simulador: http://localhost:4000
/// - Emulador de Android: http://10.0.2.2:4000
/// - Para apuntar a otro servidor:
///   flutter run --dart-define=API_URL=https://tu-servidor.com
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:4000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }

  static const Duration timeout = Duration(seconds: 20);
}