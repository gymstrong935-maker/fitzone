import '../api/api_client.dart';
import '../session/session_storage.dart';
import 'admin_service.dart';
import 'appointments_service.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'coaches_service.dart';
import 'google_auth_service.dart';
import 'notifications_service.dart';
import 'nutrition_service.dart';
import 'onboarding_sync_service.dart';
import 'payments_service.dart';
import 'plans_service.dart';
import 'subscription_service.dart';
import 'support_service.dart';
import 'user_service.dart';
import 'workouts_service.dart';

/// Contenedor de servicios. Uso: `AppServices.instance.auth.loginWithGoogle(...)`.
class AppServices {
  AppServices._() {
    auth = AuthService(api);
    plans = PlansService(api);
    subscriptions = SubscriptionService(api);
    users = UserService(api);
    notifications = NotificationsService(api);
    onboardingSync = OnboardingSyncService(api, session);
    coaches = CoachesService(api);
    appointments = AppointmentsService(api);
    chat = ChatService(api);
    workouts = WorkoutsService(api);
    nutrition = NutritionService(api);
    admin = AdminService(api);
    support = SupportService(api);
    payments = PaymentsService(api);
  }

  static final AppServices instance = AppServices._();

  final ApiClient api = ApiClient();
  final SessionStorage session = SessionStorage();
  final GoogleAuthService google = GoogleAuthService();

  late final AuthService auth;
  late final PlansService plans;
  late final SubscriptionService subscriptions;
  late final UserService users;
  late final NotificationsService notifications;
  late final OnboardingSyncService onboardingSync;
  late final CoachesService coaches;
  late final AppointmentsService appointments;
  late final ChatService chat;
  late final WorkoutsService workouts;
  late final NutritionService nutrition;
  late final AdminService admin;
  late final SupportService support;
  late final PaymentsService payments;
}