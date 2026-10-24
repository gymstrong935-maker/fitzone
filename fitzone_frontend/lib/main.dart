import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'core/api/api_exception.dart';
import 'core/models/user_profile.dart';
import 'core/services/app_services.dart';
import 'core/services/auth_service.dart';
import 'core/services/backend_models.dart';
import 'core/services/onboarding_sync_service.dart';
import 'core/services/subscription_service.dart';
import 'core/session/session_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/admin/admin_shell.dart';
import 'features/auth/account_pending_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/boot/boot_screen.dart';
import 'features/onboarding/data/trainers_repository.dart';
import 'features/onboarding/models/onboarding_data.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/payment_method/models/payment_models.dart';
import 'features/payment_method/payment_method_screen.dart';
import 'features/payment_validation/payment_validation_screen.dart';
import 'features/plan/data/plan_generator.dart';
import 'features/plan/plan_building_screen.dart';
import 'features/plan_selection/data/plans_data.dart';
import 'features/plan_selection/data/plans_mapper.dart';
import 'features/plan_selection/models/plan.dart';
import 'features/plan_selection/plan_selection_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const FitZoneApp());
}

class FitZoneApp extends StatelessWidget {
  const FitZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // El tema (claro/oscuro) cambia al instante y toda la app se vuelve a
    // dibujar con la paleta del modo elegido (ver ThemeController).
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          title: 'FitZone',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              ThemeController.instance.isLight ? ThemeMode.light : ThemeMode.dark,
          home: const AppFlow(),
        );
      },
    );
  }
}

/// Etapas de la app (el orden define la dirección de las transiciones).
enum AppStage {
  boot,
  planSelection,
  auth,
  accountPending,
  paymentMethod,
  paymentValidation,
  onboarding,
  building,
  main,
  admin,
}

class _Notice {
  const _Notice(this.title, this.message, this.icon);

  final String title;
  final String message;
  final IconData icon;
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
  Future<void>? _trainersFuture;

  BackendUser? _user;
  SubscriptionStatus? _subscriptionStatus;
  UserProfile? _profile;
  OnboardingData? _pendingData;
  BackendPayment? _activePayment;

  String? _authNotice;

  Timer? _syncTimer;

  // Splash y transiciones
  bool _splashReleased = false;
  bool _splashDone = false;
  AppStage _lastShown = AppStage.boot;
  bool _forward = true;
  _Notice? _pendingNotice;

  @override
  void initState() {
    super.initState();
    _services.api.onSessionExpired = _handleSessionExpired;
    _services.api.onAccountBlocked = _handleAccountBlocked;
    _boot();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _services.api.onSessionExpired = null;
    _services.api.onAccountBlocked = null;
    super.dispose();
  }

  void _goTo(AppStage stage) {
    if (!mounted) return;
    setState(() {
      _stage = stage;
      if (stage != AppStage.auth) _authNotice = null;
    });
  }

  // ── Splash ────────────────────────────────────────────────────────────────

  void _onSplashExit() {
    if (!mounted) return;
    setState(() => _splashReleased = true);

    final _Notice? notice = _pendingNotice;
    if (notice != null) {
      _pendingNotice = null;
      Future<void>.delayed(const Duration(milliseconds: 700), () => _presentNotice(notice));
    }
  }

  void _onSplashComplete() {
    if (mounted) setState(() => _splashDone = true);
  }

  void _showNotice(String title, String message, IconData icon) {
    final _Notice notice = _Notice(title, message, icon);
    if (!_splashReleased) {
      _pendingNotice = notice;
      return;
    }
    _presentNotice(notice);
  }

  Future<void> _presentNotice(_Notice notice) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (BuildContext ctx) => _NoticeDialog(notice: notice),
    );
  }

  // ── Arranque y sesión guardada ────────────────────────────────────────────

  Future<void> _boot() async {
    unawaited(_loadPlans());
    _trainersFuture = _loadTrainers();

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

  /// Vuelve a pedir el usuario al servidor (para ver si ya aprobaron la cuenta).
  Future<BackendUser> _refreshUser() async {
    final BackendUser? current = _user;
    if (current == null) {
      throw const ApiException('Sesión no disponible. Inicia sesión de nuevo.');
    }

    final BackendUser fresh = await _services.auth.fetchUser(current.id);
    final String? token = _services.api.token;
    if (token != null) {
      await _services.session.saveSession(token: token, userJson: fresh.raw);
    }
    _user = fresh;
    return fresh;
  }

  void _handleAccountApproved(BackendUser user) {
    _enterApp(user);
  }

  /// El servidor avisó que la cuenta quedó pendiente, rechazada, suspendida o revocada.
  void _handleAccountBlocked(String code) {
    if (!mounted) return;

    if (code == 'CUENTA_REVOCADA' || code == 'CUENTA_SUSPENDIDA') {
      final bool revoked = code == 'CUENTA_REVOCADA';
      _handleLogout();
      _showNotice(
        revoked ? 'Cuenta revocada' : 'Cuenta suspendida',
        revoked
            ? 'El equipo de FitZone revocó esta cuenta, por eso ya no puedes usarla. Si crees que es un error, contáctanos por los canales oficiales.'
            : 'Tu cuenta fue suspendida. Contacta al equipo de FitZone para más información.',
        revoked ? Icons.gpp_bad_outlined : Icons.pause_circle_outline_rounded,
      );
      return;
    }

    // Pendiente o rechazada: se muestra la pantalla de revisión.
    if (_user == null || _stage == AppStage.accountPending) return;
    _syncTimer?.cancel();
    setState(() => _stage = AppStage.accountPending);
  }

  /// Decide a dónde va un usuario que ya tiene sesión.
  Future<void> _enterApp(BackendUser user) async {
    // Cuenta de administrador: va directo al panel (sin plan ni onboarding).
    if (user.rol == 'admin') {
      if (!mounted) return;
      setState(() {
        _user = user;
        _stage = AppStage.admin;
        _authNotice = null;
      });
      return;
    }

    // Cuenta nueva: el equipo de FitZone debe aprobarla antes de continuar.
    if (user.estadoCuenta == 'pendiente' || user.estadoCuenta == 'rechazado') {
      if (!mounted) return;
      setState(() {
        _user = user;
        _stage = AppStage.accountPending;
        _authNotice = null;
      });
      return;
    }

    await _plansFuture;
    await _trainersFuture;

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
      if (status == SubscriptionStatus.pending) {
        // ¿Falta elegir cómo paga (y subir la factura)? Primero eso.
        final BackendPayment? pay = await _loadPendingPayment();
        if (!mounted) return;
        if (pay != null && pay.needsMethod) {
          _activePayment = pay;
          _goTo(AppStage.paymentMethod);
          return;
        }
        // Pago ya enviado pero onboarding hecho: puede usar la app.
        if (saved != null) {
          _openMain(user, saved);
          return;
        }
      }
      _goTo(AppStage.paymentValidation);
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
      _authNotice = null;
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

  // ── Planes y entrenadores ─────────────────────────────────────────────────

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

  /// Entrenadores reales del servidor (si no hay, se usan los del diseño).
  Future<void> _loadTrainers() async {
    try {
      TrainersRepository.set(await _services.coaches.fetch());
    } on ApiException {
      // Sin conexión: se quedan los entrenadores de respaldo.
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

  // ── Auth (solo Google) ────────────────────────────────────────────────────

  /// Inicio de sesión / registro con Google. Devuelve `null` si la persona
  /// canceló. Si la cuenta es nueva queda pendiente de aprobación y
  /// [_enterApp] la lleva a la pantalla de revisión.
  ///
  /// Con un plan elegido, quien ya tenía cuenta solo entra si es el mismo plan
  /// (mientras su inscripción siga vigente): lo comprueba el servidor.
  Future<VoidCallback?> _handleGoogleLogin() async {
    final String? idToken = await _services.google.pickIdToken();
    if (idToken == null) return null;

    final String? planId = _selectedPlan == null ? null : _currentPlan.backendId;

    try {
      final AuthResult result =
          await _services.auth.loginWithGoogle(idToken, planId: planId);
      await _services.session.saveSession(
        token: result.token,
        userJson: result.user.raw,
      );
      final BackendUser user = result.user;
      return () {
        _enterApp(user);
      };
    } on ApiException catch (e) {
      // Libera la cuenta elegida para poder probar con otra la próxima vez.
      unawaited(_services.google.signOut());
      if (e.code == 'CUENTA_REVOCADA') {
        _showNotice('Cuenta revocada', e.message, Icons.gpp_bad_outlined);
      }
      rethrow;
    }
  }

  // ── Pago ──────────────────────────────────────────────────────────────────

  /// El usuario eligió cómo paga (y subió la factura si es pago digital).
  Future<void> _handlePaymentSubmit(
    PayMethod method,
    Uint8List? receipt,
    String? receiptName,
  ) async {
    final BackendPayment? pay = _activePayment;
    if (pay == null) {
      throw const ApiException('No encontramos tu pago pendiente. Vuelve a elegir el plan.');
    }

    await _services.payments.submit(
      paymentId: pay.id,
      method: payMethodToBackend(method),
      receiptBytes: receipt,
      receiptName: receiptName,
    );
    if (!mounted) return;
    _activePayment = null;
    _subscriptionStatus = SubscriptionStatus.pending;
    _goTo(AppStage.paymentValidation);
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
    await _trainersFuture;
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
    setState(() {
      _pendingData = data;
      _stage = AppStage.building; // animación "Creando tu plan"
    });
  }

  void _finishBuilding() {
    final BackendUser? user = _user;
    final OnboardingData? data = _pendingData;
    if (user == null || data == null || _stage != AppStage.building) return;
    _pendingData = null;
    _openMain(user, data); // también empieza a enviarlo al servidor
  }

  /// Guarda el nombre nuevo en el servidor y en la sesión recordada.
  Future<void> _handleRename(String name) async {
    final BackendUser? user = _user;
    if (user == null) return;

    final BackendUser updated =
        await _services.users.updateName(userId: user.id, name: name);
    await _rememberUser(updated);
    _profile = _profile?.copyWith(name: name);
  }

  /// Nombre y correo desde "Editar perfil".
  Future<void> _handleSaveAccount(String name, String email) async {
    final BackendUser? user = _user;
    if (user == null) return;

    final BackendUser updated = await _services.users.updateProfile(
      userId: user.id,
      name: name,
      email: email,
    );
    await _rememberUser(updated);
    _profile = _profile?.copyWith(name: updated.nombre, email: updated.email);
  }

  Future<void> _handleChangePassword(
    String? current,
    String next,
    String confirmation,
  ) async {
    final BackendUser? user = _user;
    if (user == null) return;

    await _services.users.changePassword(
      userId: user.id,
      currentPassword: current,
      newPassword: next,
      confirmation: confirmation,
    );
  }

  /// Datos personales / medidas / hábitos editados: se guardan en el servidor.
  Future<void> _handleSaveData(OnboardingData before, OnboardingData after) async {
    final BackendUser? user = _user;
    if (user == null) return;

    await _services.onboardingSync.syncChanges(user.id, before, after);
  }

  Future<void> _rememberUser(BackendUser updated) async {
    final String? token = _services.api.token;
    if (token != null) {
      await _services.session.saveSession(token: token, userJson: updated.raw);
    }
    _user = updated;
  }

  /// Objetivo o datos cambiados en Ajustes (el entrenador cambia por solicitud
  /// y lo valida el equipo, no se asigna desde aquí).
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
    unawaited(_services.google.signOut());
    if (!mounted) return;
    setState(() {
      _user = null;
      _profile = null;
      _pendingData = null;
      _activePayment = null;
      _selectedPlan = null;
      _subscriptionStatus = null;
      _authNotice = null;
      _stage = AppStage.planSelection;
    });
  }

  void _handleSessionExpired() {
    if (!mounted || _stage == AppStage.planSelection) return;
    _handleLogout();
  }

  // ── Pantallas ─────────────────────────────────────────────────────────────

  Widget _buildStage(AppStage stage) {
    final ValueKey<AppStage> key = ValueKey<AppStage>(stage);

    switch (stage) {
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
          onHaveAccount: _user == null ? _handleHaveAccount : null,
          onSelectPlan: _handleSelectPlan,
        );

      case AppStage.auth:
        return AuthScreen(
          key: key,
          planName: _selectedPlan == null ? null : _currentPlan.name,
          notice: _authNotice,
          onBack: () => _goTo(AppStage.planSelection),
          onGoogleLogin: _handleGoogleLogin,
        );

      case AppStage.accountPending:
        final BackendUser? waiting = _user;
        if (waiting == null) {
          return PlanSelectionScreen(
            key: key,
            plans: _plans,
            onSelectPlan: _handleSelectPlan,
          );
        }
        return AccountPendingScreen(
          key: key,
          user: waiting,
          refresh: _refreshUser,
          onApproved: _handleAccountApproved,
          onLogout: _handleLogout,
        );

      case AppStage.paymentMethod:
        final BackendPayment? pay = _activePayment;
        if (pay == null) {
          return PlanSelectionScreen(
            key: key,
            plans: _plans,
            allowFree: _user == null,
            onLogout: _user != null ? _handleLogout : null,
            onSelectPlan: _handleSelectPlan,
          );
        }
        return PaymentMethodScreen(
          key: key,
          label: _currentPlan.name,
          amount: pay.monto,
          onSubmit: _handlePaymentSubmit,
          onBack: () => _goTo(AppStage.planSelection),
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
          // "Atrás" en el primer paso: volver a elegir plan.
          onExit: () => _goTo(AppStage.planSelection),
          onComplete: (OnboardingData data) {
            _handleOnboardingComplete(data);
          },
        );

      case AppStage.building:
        final BackendUser? builder = _user;
        final OnboardingData? data = _pendingData;
        if (builder == null || data == null) {
          return PlanSelectionScreen(
            key: key,
            plans: _plans,
            onSelectPlan: _handleSelectPlan,
          );
        }
        return PlanBuildingScreen(
          key: key,
          data: data,
          plan: generatePlan(data, since: builder.fechaRegistro),
          onDone: _finishBuilding,
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
          onSaveAccount: _handleSaveAccount,
          onChangePassword: _handleChangePassword,
          onSaveData: _handleSaveData,
        );

      case AppStage.admin:
        final BackendUser? admin = _user;
        if (admin == null) {
          return PlanSelectionScreen(
            key: key,
            plans: _plans,
            onSelectPlan: _handleSelectPlan,
          );
        }
        return AdminShell(key: key, user: admin, onLogout: _handleLogout);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hasta que la animación inicial empieza a desvanecerse se muestra el fondo
    // de arranque; así la primera pantalla entra con su propia animación.
    final AppStage shown = _splashReleased ? _stage : AppStage.boot;
    if (shown != _lastShown) {
      _forward = shown.index >= _lastShown.index;
      _lastShown = shown;
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (Widget? current, List<Widget> previous) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[...previous, if (current != null) current],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            final bool incoming = child.key == ValueKey<AppStage>(shown);
            final double dx = (incoming ? 1 : -1) * (_forward ? 1 : -1) * 28.0;

            return FadeTransition(
              opacity: animation,
              child: AnimatedBuilder(
                animation: animation,
                child: child,
                builder: (BuildContext context, Widget? c) {
                  final double v = animation.value;
                  return Transform.translate(
                    offset: Offset((1 - v) * dx, 0),
                    child: Transform.scale(scale: 0.985 + 0.015 * v, child: c),
                  );
                },
              ),
            );
          },
          child: _buildStage(shown),
        ),
        if (!_splashDone)
          SplashScreen(
            key: const ValueKey<String>('splash'),
            onExit: _onSplashExit,
            onComplete: _onSplashComplete,
          ),
      ],
    );
  }
}

/// Aviso de cuenta revocada / suspendida.
class _NoticeDialog extends StatelessWidget {
  const _NoticeDialog({required this.notice});

  final _Notice notice;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (BuildContext context, double v, Widget? child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.whiteA(0.10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(239, 68, 68, 0.12),
                      border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.30)),
                    ),
                    child: Icon(notice.icon, size: 30, color: AppColors.red),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  notice.title,
                  textAlign: TextAlign.center,
                  style: AppText.display(size: 21, weight: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  notice.message,
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 14, color: AppColors.whiteA(0.60), height: 1.55),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: <Color>[AppColors.cyan, AppColors.teal],
                      ),
                    ),
                    child: Text(
                      'Entendido',
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}