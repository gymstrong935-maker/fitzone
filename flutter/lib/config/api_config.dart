class ApiConfig {
  ApiConfig._();

  /*
   * Android Emulator:
   * 10.0.2.2 apunta al localhost de tu computador.
   *
   * iOS Simulator:
   * puedes utilizar localhost.
   *
   * Celular físico:
   * debes colocar la IP local de tu computador.
   */

  static const String baseUrl = 'http://10.0.2.2:4000/api';

  static const String users = '$baseUrl/users';
  static const String plans = '$baseUrl/plans';
  static const String coaches = '$baseUrl/coaches';
  static const String groups = '$baseUrl/groups';
  static const String payments = '$baseUrl/payments';
  static const String subscriptions = '$baseUrl/subscriptions';
  static const String notifications = '$baseUrl/notifications';

  static const String physicalConditions =
      '$baseUrl/physical-conditions';

  static const String physicalMeasurements =
      '$baseUrl/physical-measurements';

  static const String sleepQuality =
      '$baseUrl/sleep-quality';

  static const String motivation =
      '$baseUrl/motivation';

  static const String trainingFrequency =
      '$baseUrl/training-frequency';

  static const String trainingParameters =
      '$baseUrl/training-parameters';

  static const String trainingPeriods =
      '$baseUrl/training-periods';

  static const String dietaryControl =
      '$baseUrl/dietary-control';

  static const String appointments =
      '$baseUrl/appointments';

  static const String chat =
      '$baseUrl/chat';
}