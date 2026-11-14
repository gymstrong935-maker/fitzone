
import 'package:flutter/foundation.dart';

/// Configuración de la API de FitZone.
class ApiConfig {
  ApiConfig._();

  /// true = backend remoto en Render
  /// false = backend local
  static const bool useRemote = true;

  /// URL del backend desplegado.
  static const String remoteUrl =
      'https://fitzone-0hut.onrender.com';

  /// URL del backend local.
  static const String localUrl = 'http://localhost:4000';

  /// Permite sobrescribir la URL al ejecutar Flutter.
  static const String _override =
      String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }

    if (useRemote) {
      return remoteUrl;
    }

    if (kIsWeb) {
      return localUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }

    return localUrl;
  }

  static const Duration timeout = Duration(seconds: 20);
}
