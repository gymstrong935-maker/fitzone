import '../api/api_client.dart';
import '../session/session_storage.dart';
import 'auth_service.dart';
import 'notifications_service.dart';
import 'onboarding_sync_service.dart';
import 'plans_service.dart';
import 'subscription_service.dart';
import 'user_service.dart';

/// Contenedor de servicios. Uso: `AppServices.instance.auth.login(...)`.
class AppServices {
  AppServices._() {
    auth = AuthService(api);
    plans = PlansService(api);
    subscriptions = SubscriptionService(api);
    users = UserService(api);
    notifications = NotificationsService(api);
    onboardingSync = OnboardingSyncService(api, session);
  }

  static final AppServices instance = AppServices._();

  final ApiClient api = ApiClient();
  final SessionStorage session = SessionStorage();

  late final AuthService auth;
  late final PlansService plans;
  late final SubscriptionService subscriptions;
  late final UserService users;
  late final NotificationsService notifications;
  late final OnboardingSyncService onboardingSync;
}