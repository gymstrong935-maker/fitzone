import '../../features/onboarding/models/onboarding_data.dart';
import '../../features/onboarding/models/body_measurements.dart';
import '../../features/onboarding/models/experience_level.dart';
import '../../features/onboarding/models/goal.dart';
import '../../features/onboarding/models/personal_info.dart';
import '../../features/onboarding/models/trainer.dart';
import '../../features/onboarding/models/training_habits.dart';
import '../../features/payment_method/models/payment_models.dart';
import '../../features/plan_selection/models/plan.dart';
import 'api_client.dart';
import 'api_exception.dart';

class FitZoneApi {
  FitZoneApi._();

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final dynamic json = await ApiClient.post(
      '/users/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );
    final AuthResult result = _parseAuth(json);
    await ApiClient.saveSession(token: result.token, userId: result.user.id);
    return result;
  }

  static Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
    String? planId,
  }) async {
    final dynamic json = await ApiClient.post(
      '/users/register',
      body: <String, dynamic>{
        'nombre': name,
        'email': email,
        'password': password,
        if (planId != null) 'planId': planId,
      },
    );
    final Map<String, dynamic> data = _map(json);
    return RegisterResult(
      message: (data['mensaje'] ?? 'Registro completado').toString(),
      user: data['usuario'] == null ? null : AuthUserData.fromJson(_map(data['usuario'])),
    );
  }

  static Future<void> verifyAccount({
    required String email,
    required String code,
  }) async {
    await ApiClient.post(
      '/users/verificar-cuenta',
      body: <String, dynamic>{'email': email, 'codigo': code},
    );
  }

  static Future<void> resendVerification(String email) async {
    await ApiClient.post(
      '/users/reenviar-codigo',
      body: <String, dynamic>{'email': email},
    );
  }

  static Future<void> forgotPassword(String email) async {
    await ApiClient.post(
      '/users/forgot-password',
      body: <String, dynamic>{'email': email},
    );
  }

  static Future<List<BackendPlan>> getPlans() async {
    final dynamic json = await ApiClient.get('/plans');
    if (json is! List) return <BackendPlan>[];
    return json
        .whereType<Map<String, dynamic>>()
        .map(BackendPlan.fromJson)
        .toList();
  }

  static Future<void> changePlan({
    required String planId,
    required PayMethod method,
  }) async {
    await ApiClient.post(
      '/subscriptions/cambiar-plan',
      authenticated: true,
      body: <String, dynamic>{
        'nuevoPlanId': planId,
        'metodoPago': paymentMethodApiValue(method),
      },
    );
  }

  static Future<List<Trainer>> getCoaches() async {
    final dynamic json = await ApiClient.get('/coaches');
    if (json is! List) return <Trainer>[];
    return json.whereType<Map<String, dynamic>>().map(_trainerFromJson).toList();
  }

  static Future<OnboardingResult> saveOnboarding(OnboardingData data) async {
    final dynamic json = await ApiClient.post(
      '/onboarding',
      authenticated: true,
      body: _onboardingPayload(data),
    );
    final Map<String, dynamic> map = _map(json);
    return OnboardingResult.fromJson(map);
  }

  static Future<AuthUserData> getCurrentUser() async {
    final String? id = await ApiClient.storedUserId();
    if (id == null || id.isEmpty) {
      throw const ApiException('No hay una sesión guardada.');
    }
    final dynamic json = await ApiClient.get('/users/$id', authenticated: true);
    return AuthUserData.fromJson(_map(json));
  }

  static Future<OnboardingResult?> getOnboarding() async {
    try {
      final dynamic json = await ApiClient.get('/onboarding/me', authenticated: true);
      if (json is! Map<String, dynamic>) return null;
      if (json['completado'] != true) return null;
      return OnboardingResult.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<void> logout() => ApiClient.clearSession();

  static AuthResult _parseAuth(dynamic json) {
    final Map<String, dynamic> data = _map(json);
    final String token = (data['token'] ?? '').toString();
    final AuthUserData user = AuthUserData.fromJson(_map(data['usuario']));
    if (token.isEmpty || user.id.isEmpty) {
      throw const ApiException('El servidor no devolvió una sesión válida.');
    }
    return AuthResult(token: token, user: user, message: (data['mensaje'] ?? '').toString());
  }

  static Map<String, dynamic> _onboardingPayload(OnboardingData data) {
    final PersonalInfo info = data.personalInfo.sanitized();
    final BodyMeasurements measurements = data.bodyMeasurements;
    final TrainingHabits habits = data.trainingHabits;
    final double weightKg = info.weightUnit == WeightUnit.kg
        ? info.weight
        : info.weight / 2.20462;

    return <String, dynamic>{
      'personal': <String, dynamic>{
        'edad': info.age,
        'genero': _genderApiValue(info.gender),
        'peso': double.parse(weightKg.toStringAsFixed(2)),
        'unidadPeso': info.weightUnit.name,
        'alturaCm': info.height,
        'condicionFisica': info.physicalCondition,
        'motivacion': info.psychologicalCondition.motivation,
        'estres': info.psychologicalCondition.stress,
        'energia': info.psychologicalCondition.energy,
        'condicionesMedicas': info.medicalConditions.physical,
      },
      'mediciones': <String, dynamic>{
        'peso': double.parse(weightKg.toStringAsFixed(2)),
        'altura': double.parse((info.height / 100).toStringAsFixed(3)),
        'medidas': <String, dynamic>{
          if (measurements.circumferences[CircumferenceSite.waist] != null)
            'cintura': measurements.circumferences[CircumferenceSite.waist],
          if (measurements.circumferences[CircumferenceSite.hip] != null)
            'cadera': measurements.circumferences[CircumferenceSite.hip],
          if (measurements.circumferences[CircumferenceSite.chest] != null)
            'pecho': measurements.circumferences[CircumferenceSite.chest],
          if (measurements.circumferences[CircumferenceSite.arm] != null)
            'brazo': measurements.circumferences[CircumferenceSite.arm],
          if (measurements.circumferences[CircumferenceSite.thigh] != null)
            'muslo': measurements.circumferences[CircumferenceSite.thigh],
          if (measurements.circumferences[CircumferenceSite.calf] != null)
            'pantorrilla': measurements.circumferences[CircumferenceSite.calf],
        },
        'pliegues': _skinfoldMap(measurements),
      },
      'objetivo': data.goal?.apiValue,
      'nivelExperiencia': data.experienceLevel?.apiValue,
      'habitos': <String, dynamic>{
        'frecuencia': habits.frequency,
        'duracionMinutos': habits.duration,
        'calidadSueno': habits.sleepQuality.apiValue,
        'horasSueno': habits.sleepDuration,
        'nivelActividad': habits.activityLevel.apiValue,
        'disponibilidad': habits.availability,
      },
      'coachId': data.trainer?.id,
      'coachNombre': data.trainer?.name,
    };
  }

  static Map<String, double> _skinfoldMap(BodyMeasurements m) {
    final Map<String, double> out = <String, double>{};
    void add(SkinfoldSite site, String api) {
      final double? value = m.skinfolds[site];
      if (value != null) out[api] = value;
    }
    add(SkinfoldSite.triceps, 'triceps');
    add(SkinfoldSite.subscapular, 'subscapular');
    add(SkinfoldSite.chest, 'chest');
    add(SkinfoldSite.abdominal, 'abdominal');
    add(SkinfoldSite.thigh, 'thigh');
    add(SkinfoldSite.suprailiac, 'suprailiac');
    add(SkinfoldSite.midaxillary, 'midaxillary');
    return out;
  }

  static String _genderApiValue(Gender value) {
    switch (value) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
    }
  }

  static String paymentMethodApiValue(PayMethod method) {
    switch (method) {
      case PayMethod.cash:
        return 'Efectivo';
      case PayMethod.card:
        return 'Tarjeta';
      case PayMethod.digital:
        return 'Nequi';
    }
  }

  static Trainer _trainerFromJson(Map<String, dynamic> json) {
    final List<String> specialties = (json['especialidad'] as List? ?? const [])
        .map((dynamic e) => e.toString())
        .toList();
    final List<String> certifications = (json['certificaciones'] as List? ?? const [])
        .map((dynamic e) => e.toString())
        .toList();
    final List<String> services = (json['servicios'] as List? ?? const [])
        .map((dynamic e) => e.toString())
        .toList();
    TrainerLevel level = TrainerLevel.standard;
    switch ((json['nivel'] ?? 'standard').toString()) {
      case 'premium': level = TrainerLevel.premium; break;
      case 'elite': level = TrainerLevel.elite; break;
    }
    return Trainer(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['nombre'] ?? 'Entrenador').toString(),
      photo: (json['fotoPerfil'] ?? '').toString(),
      specialty: specialties.isEmpty ? 'Entrenamiento personalizado' : specialties.first,
      experience: (json['experiencia'] as num?)?.toInt() ?? 0,
      certifications: certifications,
      rating: (json['calificacionPromedio'] as num?)?.toDouble() ?? 0,
      description: (json['descripcion'] ?? 'Entrenador FitZone').toString(),
      trainingType: (json['tipoEntrenamiento'] ?? 'Personalizado').toString(),
      price: (json['precio'] as num?)?.toInt() ?? 0,
      priceDescription: (json['precioDescripcion'] ?? '/mes').toString(),
      services: services,
      level: level,
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const ApiException('Respuesta inválida del servidor.');
  }
}


class AuthResult {
  const AuthResult({required this.token, required this.user, required this.message});
  final String token;
  final AuthUserData user;
  final String message;
}

class RegisterResult {
  const RegisterResult({required this.message, required this.user});
  final String message;
  final AuthUserData? user;
}

class AuthUserData {
  const AuthUserData({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? phone;

  factory AuthUserData.fromJson(Map<String, dynamic> json) {
    return AuthUserData(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['nombre'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['fechaRegistro'] ?? '').toString()) ?? DateTime.now(),
      phone: json['telefono']?.toString(),
    );
  }
}

class BackendPlan {
  const BackendPlan({required this.id, required this.name, required this.free});
  final String id;
  final String name;
  final bool free;

  factory BackendPlan.fromJson(Map<String, dynamic> json) => BackendPlan(
        id: (json['_id'] ?? '').toString(),
        name: (json['nombre'] ?? '').toString(),
        free: json['esGratuito'] == true,
      );
}

class OnboardingResult {
  const OnboardingResult({required this.completed, this.coachName, this.groupName});
  final bool completed;
  final String? coachName;
  final String? groupName;

  factory OnboardingResult.fromJson(Map<String, dynamic> json) => OnboardingResult(
        completed: json['completado'] == true,
        coachName: json['coachNombre']?.toString(),
        groupName: json['grupoAsignado']?.toString(),
      );
}
