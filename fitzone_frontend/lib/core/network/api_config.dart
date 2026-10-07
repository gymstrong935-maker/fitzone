class ApiConfig {
  ApiConfig._();

  /// Android Emulator: 10.0.2.2 apunta al localhost de tu PC.
  ///
  /// También puedes ejecutar con:
  /// flutter run --dart-define=FITZONE_API_URL=http://192.168.1.50:4000/api
  /// para un teléfono físico conectado a la misma red.
  static const String baseUrl = String.fromEnvironment(
    'FITZONE_API_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );
}
