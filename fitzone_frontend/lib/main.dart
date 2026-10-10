import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api/api_exception.dart';
import 'core/models/user_profile.dart';
import 'core/services/app_services.dart';
import 'core/services/auth_service.dart';
import 'core/services/backend_models.dart';
import 'core/services/onboarding_sync_service.dart';
import 'core/services/subscription_service.dart';
import 'core/session/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/email_verification_screen.dart';
import 'features/boot/boot_screen.dart';
import 'features/onboarding/models/onboarding_data.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/payment_method/models/payment_models.dart';
import 'features/payment_method/payment_method_screen.dart';
import 'features/payment_validation/payment_validation_screen.dart';
import 'features/plan_selection/data/plans_data.dart';
import 'features/plan_selection/data/plans_mapper.dart';
import 'features/plan_selection/models/plan.dart';
import 'features/plan_selection/plan_selection_screen.dart';
import 'features/shell/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
    ),
  );
  runApp(const FitZoneApp());
}

class FitZoneApp extends StatelessWidget {
  const FitZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitZone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppFlow(),
    );
  }
}

/// Etapas de la app.
enum AppStage {
  boot,
  planSelection,
  auth,
  emailVerification,
  paymentMethod,
  paymentValidation,
  onboarding,
  main,
}

/// Datos del registro que se guardan en memoria hasta crear la cuenta.
class _RegistrationDraft {
  const _RegistrationDraft({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  final AppServices _services = AppServices.instance;

  AppStage _stage = AppStage.boot;
  PlanId? _selectedPlan;

  List<Plan> _plans = kPlans;
  String? _plansError;
  Future<void>? _plansFuture;

  _RegistrationDraft? _draft;
  BackendUser? _user;
  SubscriptionStatus? _subscriptionStatus;
  UserProfile? _profile;

  /// Reintenta enviar el onboarding al servidor mientras falte algo
  /// (por ejemplo, hasta que aprueben el pago).
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _services.api.onSessionExpired = _handleSessionExpired;
    _boot();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _services.api.onSessionExpired = null;
    super.dispose();
  }

  void _goTo(AppStage stage) {
    if (mounted) setState(() => _stage = stage);
  }

  // ── Arranque y sesión guardada ────────────────────────────────────────────

  Future<void> _boot() async {
    unawaited(_loadPlans());

    final StoredSession? stored = await _services.session.readSession();
    if (stored == null) {
      _goTo(AppStage.planSelection);
      return;
    }

    _services.api.setToken(stored.token);
    BackendUser user = BackendUser.fromJson(stored.userJson);

    try {
      // Confirma que el token sigue sirviendo y refresca los datos.
      user = await _services.auth.fetchUser(user.id);
      await _services.session.saveSession(token: stored.token, userJson: user.raw);
    } on ApiException catch (e) {
      if (!e.isNetwork) {
        await _clearSession();
        _goTo(AppStage.planSelection);
        return;
      }
      // Sin conexión: seguimos con los datos guardados.
    }

    if (!mounted) return;
    await _enterApp(user);
  }

  Future<void> _clearSession() async {
    _services.api.setToken(null);
    await _services.session.clearSession();
  }

  /// Decide a dónde va un usuario que ya tiene sesión.
  Future<void> _enterApp(BackendUser user) async {
    await _plansFuture;

    SubscriptionStatus? status;
    try {
      status = await _services.subscriptions.statusFor(user.id);
    } on ApiException {
      status = null; // no se pudo consultar: se asume que todo está bien
    }

    OnboardingData? saved = await _services.session.readOnboarding(user.id);
    if (!mounted) return;

    _user = user;
    _subscriptionStatus = status;
    _selectedPlan = _planIdForBackend(user.planActual);

    if (status != null && status != SubscriptionStatus.active) {
      // Pago pendiente pero onboarding ya hecho: puede usar la app.
      if (status == SubscriptionStatus.pending && saved != null) {
        _openMain(user, saved);
      } else {
        _goTo(AppStage.paymentValidation);
      }
      return;
    }

    // Sin datos en este dispositivo: se intenta recuperar lo guardado en el
    // servidor (por ejemplo, al iniciar sesión desde otro navegador).
    saved ??= await _restoreFromServer(user);
    if (!mounted) return;

    if (saved == null) {
      _goTo(AppStage.onboarding);
    } else {
      _openMain(user, saved);
    }
  }

  Future<OnboardingData?> _restoreFromServer(BackendUser user) async {
    try {
      final OnboardingData? remote =
          await _services.onboardingSync.restore(user.id, user.raw);
      if (remote != null) {
        await _services.session.saveOnboarding(user.id, remote);
      }
      return remote;
    } on ApiException {
      return null; // sin conexión o error: se pide el onboarding de nuevo
    }
  }

  void _openMain(BackendUser user, OnboardingData data) {
    setState(() {
      _profile = UserProfile(
        id: user.id,
        name: user.nombre.isEmpty ? 'Usuario FitZone' : user.nombre,
        email: user.email,
        createdAt: user.fechaRegistro,
        onboardingData: data,
      );
      _stage = AppStage.main;
    });
    _startSyncLoop(user.id);
  }

  PlanId _planIdForBackend(String? backendId) {
    for (final Plan p in _plans) {
      if (p.backendId != null && p.backendId == backendId) return p.id;
    }
    return _selectedPlan ?? PlanId.free;
  }

  // ── Sincronización del onboarding con el servidor ─────────────────────────

  void _startSyncLoop(String userId) {
    _syncTimer?.cancel();

    Future<void> run() async {
      final OnboardingData? data = _profile?.onboardingData;
      if (data == null) return;
      try {
        final SyncResult result =
            await _services.onboardingSync.syncPending(userId, data);
        if (result.isComplete) _syncTimer?.cancel();
      } catch (_) {
        // Se vuelve a intentar en el siguiente ciclo.
      }
    }

    unawaited(run());
    _syncTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(run()),
    );
  }

  // ── Planes ────────────────────────────────────────────────────────────────

  Future<void> _loadPlans() {
    final Future<void> future = _fetchPlans();
    _plansFuture = future;
    return future;
  }

  Future<void> _fetchPlans() async {
    if (mounted) setState(() => _plansError = null);
    try {
      final List<BackendPlan> backend = await _services.plans.fetch();
      if (!mounted) return;
      setState(() => _plans = mergePlansWithBackend(backend));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _plansError = e.message);
    }
  }

  Plan get _currentPlan {
    final PlanId id = _selectedPlan ?? PlanId.free;
    return _plans.firstWhere((Plan p) => p.id == id, orElse: () => kPlans.first);
  }

  void _handleSelectPlan(PlanId plan) {
    setState(() {
      _selectedPlan = plan;
      // Con cuenta: va directo a elegir cómo pagar. Sin cuenta: Auth.
      _stage = _user != null ? AppStage.paymentMethod : AppStage.auth;
    });
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<VoidCallback> _handleLogin(String email, String password) async {
    try {
      final AuthResult result = await _services.auth.login(
        email: email,
        password: password,
      );
      await _services.session.saveSession(
        token: result.token,
        userJson: result.user.raw,
      );
      final BackendUser user = result.user;
      return () {
        _enterApp(user);
      };
    } on ApiException catch (e) {
      final bool unverified = e.code == 'CUENTA_NO_VERIFICADA' ||
          e.message.contains('verificar tu cuenta');
      if (!unverified) rethrow;

      // La cuenta existe pero falta el código del correo.
      _draft = _RegistrationDraft(name: '', email: email, password: password);
      try {
        await _services.auth.resendCode(email);
      } on ApiException {
        // Se puede reenviar desde la pantalla de verificación.
      }
      return () => _goTo(AppStage.emailVerification);
    }
  }

  Future<VoidCallback> _handleRegister(
    String name,
    String email,
    String password,
  ) async {
    _draft = _RegistrationDraft(name: name, email: email, password: password);

    // Plan gratuito: se crea la cuenta ya. Planes de pago: primero el método
    // de pago (el registro lleva plan + método en una sola llamada).
    if (_currentPlan.id == PlanId.free) {
      await _registerAccount();
      return () => _goTo(AppStage.emailVerification);
    }
    return () => _goTo(AppStage.paymentMethod);
  }

  Future<void> _registerAccount({String? metodoPago}) async {
    final _RegistrationDraft? draft = _draft;
    if (draft == null) {
      throw const ApiException('Falta información del registro. Vuelve a empezar.');
    }

    await _plansFuture;
    String? planId = _currentPlan.backendId;
    if (planId == null) {
      await _loadPlans();
      planId = _currentPlan.backendId;
    }
    if (planId == null) {
      throw const ApiException(
        'No pudimos cargar los planes del servidor. Revisa tu conexión e inténtalo de nuevo.',
      );
    }

    await _services.auth.register(
      nombre: draft.name,
      email: draft.email,
      password: draft.password,
      planId: planId,
      metodoPago: metodoPago,
    );
  }

  Future<void> _handleForgotPassword(String email) {
    return _services.auth.forgotPassword(email);
  }

  // ── Verificación de correo ────────────────────────────────────────────────

  Future<VoidCallback> _handleVerify(String code) async {
    final _RegistrationDraft? draft = _draft;
    if (draft == null) {
      throw const ApiException(
        'La sesión de registro expiró. Inicia sesión de nuevo.',
      );
    }

    try {
      await _services.auth.verifyAccount(email: draft.email, code: code);
    } on ApiException catch (e) {
      // Si ya estaba verificada, simplemente seguimos con el inicio de sesión.
      if (!e.message.contains('ya está verificada')) rethrow;
    }

    final AuthResult result = await _services.auth.login(
      email: draft.email,
      password: draft.password,
    );
    await _services.session.saveSession(
      token: result.token,
      userJson: result.user.raw,
    );

    _draft = null;
    final BackendUser user = result.user;
    return () {
      _enterApp(user);
    };
  }

  Future<void> _handleResend() async {
    final _RegistrationDraft? draft = _draft;
    if (draft == null) return;
    await _services.auth.resendCode(draft.email);
  }

  // ── Pago ──────────────────────────────────────────────────────────────────

  Future<void> _handlePaymentMethod(PayMethod method) async {
    final String metodoPago = payMethodToBackend(method);
    final BackendUser? user = _user;

    if (user != null) {
      // Usuario con cuenta que pide otro plan.
      final String? planId = _currentPlan.backendId;
      if (planId == null) {
        throw const ApiException(
          'No pudimos cargar los planes del servidor. Inténtalo de nuevo.',
        );
      }
      await _services.subscriptions.changePlan(
        userId: user.id,
        planId: planId,
        metodoPago: metodoPago,
      );
      if (!mounted) return;
      _subscriptionStatus = SubscriptionStatus.pending;
      _goTo(AppStage.paymentValidation);
      return;
    }

    // Registro nuevo con plan de pago.
    await _registerAccount(metodoPago: metodoPago);
    if (!mounted) return;
    _goTo(AppStage.emailVerification);
  }

  Future<SubscriptionStatus> _fetchSubscriptionStatus() async {
    final BackendUser? user = _user;
    if (user == null) return SubscriptionStatus.none;
    final SubscriptionStatus status =
        await _services.subscriptions.statusFor(user.id);
    _subscriptionStatus = status;
    return status;
  }

  /// Tras validar el pago (o "continuar mientras tanto").
  Future<void> _continueAfterPayment() async {
    final BackendUser? user = _user;
    if (user == null) return;
    final OnboardingData? saved = await _services.session.readOnboarding(user.id);
    if (!mounted) return;
    if (saved == null) {
      _goTo(AppStage.onboarding);
    } else {
      _openMain(user, saved);
    }
  }

  // ── Onboarding, perfil y cierre de sesión ─────────────────────────────────

  Future<void> _handleOnboardingComplete(OnboardingData data) async {
    final BackendUser? user = _user;
    if (user == null) return;
    await _services.session.saveOnboarding(user.id, data);
    if (!mounted) return;
    _openMain(user, data); // también empieza a enviarlo al servidor
  }

  /// Guarda el nombre nuevo en el servidor y en la sesión recordada.
  Future<void> _handleRename(String name) async {
    final BackendUser? user = _user;
    if (user == null) return;

    final BackendUser updated =
        await _services.users.updateName(userId: user.id, name: name);

    final String? token = _services.api.token;
    if (token != null) {
      await _services.session.saveSession(token: token, userJson: updated.raw);
    }
    _user = updated;
    _profile = _profile?.copyWith(name: name);
  }

  /// Objetivo o entrenador cambiados en Ajustes.
  void _handleProfileChanged(UserProfile previous, UserProfile next) {
    final BackendUser? user = _user;
    if (user == null) return;

    _profile = next;
    unawaited(_services.session.saveOnboarding(user.id, next.onboardingData));

    // Un nuevo objetivo es un nuevo período de entrenamiento en el servidor.
    final goal = next.onboardingData.goal;
    if (goal != null && goal != previous.onboardingData.goal) {
      unawaited(
        _services.onboardingSync.syncGoal(user.id, goal).catchError((Object e) {
          debugPrint('No se pudo guardar el objetivo en el servidor: $e');
        }),
      );
    }
  }

  void _handleLogout() {
    _syncTimer?.cancel();
    _clearSession();
    if (!mounted) return;
    setState(() {
      _user = null;
      _profile = null;
      _draft = null;
      _selectedPlan = null;
      _subscriptionStatus = null;
      _stage = AppStage.planSelection;
    });
  }

  void _handleSessionExpired() {
    if (!mounted || _stage == AppStage.planSelection) return;
    _handleLogout();
  }

  // ── Pantallas ─────────────────────────────────────────────────────────────

  Widget _buildStage() {
    final ValueKey<AppStage> key = ValueKey<AppStage>(_stage);

    switch (_stage) {
      case AppStage.boot:
        return BootScreen(key: key);

      case AppStage.planSelection:
        return PlanSelectionScreen(
          key: key,
          plans: _plans,
          errorMessage: _plansError,
          onRetry: _loadPlans,
          allowFree: _user == null,
          onLogout: _user != null ? _handleLogout : null,
          onSelectPlan: _handleSelectPlan,
        );

      case AppStage.auth:
        return AuthScreen(
          key: key,
          onBack: () => _goTo(AppStage.planSelection),
          onLogin: _handleLogin,
          onRegister: _handleRegister,
          onForgotPassword: _handleForgotPassword,
        );

      case AppStage.emailVerification:
        return EmailVerificationScreen(
          key: key,
          email: _draft?.email ?? '',
          onVerify: _handleVerify,
          onResend: _handleResend,
          onBack: () => _goTo(AppStage.auth),
        );

      case AppStage.paymentMethod:
        return PaymentMethodScreen(
          key: key,
          planType: _selectedPlan ?? PlanId.monthly,
          onContinue: _handlePaymentMethod,
          onBack: () =>
              _goTo(_user != null ? AppStage.planSelection : AppStage.auth),
        );

      case AppStage.paymentValidation:
        return PaymentValidationScreen(
          key: key,
          initialStatus: _subscriptionStatus,
          fetchStatus: _fetchSubscriptionStatus,
          onApproved: _continueAfterPayment,
          onSkip: _continueAfterPayment,
          onChoosePlan: () => _goTo(AppStage.planSelection),
          onLogout: _handleLogout,
        );

      case AppStage.onboarding:
        return OnboardingFlow(
          key: key,
          planType: _selectedPlan ?? PlanId.free,
          onComplete: (OnboardingData data) {
            _handleOnboardingComplete(data);
          },
        );

      case AppStage.main:
        final UserProfile? profile = _profile;
        if (profile == null) {
          return PlanSelectionScreen(
            key: key,
            plans: _plans,
            onSelectPlan: _handleSelectPlan,
          );
        }
        return MainShell(
          key: key,
          userProfile: profile,
          onLogout: _handleLogout,
          onRename: _handleRename,
          onProfileChanged: _handleProfileChanged,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: const Cubic(0.22, 1, 0.36, 1),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool incoming = child.key == ValueKey<AppStage>(_stage);
        final double dy = incoming ? 18.0 : -18.0;
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (BuildContext context, Widget? c) {
              return Transform.translate(
                offset: Offset(0, (1 - animation.value) * dy),
                child: c,
              );
            },
          ),
        );
      },
      child: _buildStage(),
    );
  }
}