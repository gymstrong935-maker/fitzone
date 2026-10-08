import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/models/user_profile.dart';
import 'core/network/api_exception.dart';
import 'core/network/fitzone_api.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/models/auth_models.dart';
import 'features/onboarding/models/onboarding_data.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/payment_method/models/payment_models.dart';
import 'features/payment_method/payment_method_screen.dart';
import 'features/plan_selection/models/plan.dart';
import 'features/plan_selection/plan_selection_screen.dart';
import 'features/shell/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
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

enum AppStage {
  planSelection,
  auth,
  paymentMethod,
  paymentValidation,
  onboarding,
  main,
}

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  AppStage _stage = AppStage.planSelection;
  PlanId? _selectedPlan;
  String? _backendPlanId;
  AuthUser? _user;
  PayMethod? _paymentMethod;
  UserProfile? _profile;
  bool _working = false;

  void _handleSelectPlan(PlanId plan) {
    _selectPlanAsync(plan);
  }

  Future<void> _selectPlanAsync(PlanId plan) async {
    setState(() => _working = true);
    try {
      final List<BackendPlan> plans = await FitZoneApi.getPlans();
      final String expected = switch (plan) {
        PlanId.free => 'Gratuito',
        PlanId.monthly => 'Mensual',
        PlanId.annual => 'Anual',
      };
      final BackendPlan selected = plans.firstWhere(
        (BackendPlan item) => item.name.toLowerCase() == expected.toLowerCase(),
        orElse: () => throw const ApiException(
          'No se encontró el plan seleccionado. Ejecuta npm run seed en el backend.',
        ),
      );

      if (!mounted) return;
      setState(() {
        _selectedPlan = plan;
        _backendPlanId = selected.id;
        // Todos los planes crean una cuenta. El gratuito ya no es anónimo.
        _stage = AppStage.auth;
      });
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _handleAuthSuccess(AuthUser user) {
    setState(() {
      _user = user;
      _stage = (_selectedPlan == PlanId.free) ? AppStage.onboarding : AppStage.paymentMethod;
    });
  }

  Future<void> _handlePaymentMethodSelected(PayMethod method) async {
    final String? planId = _backendPlanId;
    if (planId == null) {
      throw const ApiException('No se encontró el ID del plan. Regresa y selecciónalo nuevamente.');
    }

    await FitZoneApi.changePlan(planId: planId, method: method);
    if (!mounted) return;
    setState(() {
      _paymentMethod = method;
      _stage = AppStage.paymentValidation;
    });
  }

  Future<void> _handleOnboardingComplete(OnboardingData data) async {
    final AuthUser? user = _user;
    if (user == null) {
      throw const ApiException('La sesión no está disponible. Inicia sesión nuevamente.');
    }

    await FitZoneApi.saveOnboarding(data);
    if (!mounted) return;

    setState(() {
      _profile = UserProfile(
        id: user.id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
        onboardingData: data,
      );
      _stage = AppStage.main;
    });
  }

  void _handleLogout() {
    _logoutAsync();
  }

  Future<void> _logoutAsync() async {
    await FitZoneApi.logout();
    if (!mounted) return;
    setState(() {
      _profile = null;
      _user = null;
      _selectedPlan = null;
      _backendPlanId = null;
      _paymentMethod = null;
      _stage = AppStage.planSelection;
    });
  }

  Widget _buildStage() {
    final ValueKey<AppStage> key = ValueKey<AppStage>(_stage);

    switch (_stage) {
      case AppStage.planSelection:
        return Stack(
          children: <Widget>[
            PlanSelectionScreen(key: key, onSelectPlan: _handleSelectPlan),
            if (_working)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x88000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );

      case AppStage.auth:
        return AuthScreen(
          key: key,
          planType: _selectedPlan ?? PlanId.free,
          onAuthSuccess: _handleAuthSuccess,
          onBack: () => _goTo(AppStage.planSelection),
        );

      case AppStage.paymentMethod:
        return PaymentMethodScreen(
          key: key,
          planType: _selectedPlan ?? PlanId.monthly,
          onContinue: _handlePaymentMethodSelected,
          onBack: () => _goTo(AppStage.auth),
        );

      case AppStage.paymentValidation:
        return _PlaceholderScreen(
          key: key,
          title: 'Solicitud de pago enviada',
          message:
              'Método: ${_paymentMethod?.name ?? '-'}\n\n'
              'Tu solicitud quedó registrada como pendiente. El equipo de FitZone la validará y activará tu plan.\n\n'
              'Ahora completa tu configuración personal.',
          onBack: () => _goTo(AppStage.paymentMethod),
          onNext: () => _goTo(AppStage.onboarding),
          nextLabel: 'Continuar con mi perfil',
        );

      case AppStage.onboarding:
        return OnboardingFlow(
          key: key,
          planType: _selectedPlan ?? PlanId.free,
          onComplete: _handleOnboardingComplete,
        );

      case AppStage.main:
        final UserProfile? profile = _profile;
        if (profile == null) {
          return PlanSelectionScreen(key: key, onSelectPlan: _handleSelectPlan);
        }
        return MainShell(key: key, userProfile: profile, onLogout: _handleLogout);
    }
  }

  void _goTo(AppStage stage) => setState(() => _stage = stage);

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

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onBack,
    this.onNext,
    this.nextLabel = 'Continuar',
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: AppText.display(size: 28)),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppText.body(size: 13, color: AppColors.whiteA(0.55), height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  if (onNext != null)
                    TextButton(
                      onPressed: onNext,
                      child: Text(nextLabel, style: AppText.body(size: 14, color: AppColors.cyan)),
                    ),
                  TextButton(
                    onPressed: onBack,
                    child: Text('Volver', style: AppText.body(size: 14, color: AppColors.whiteA(0.6))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
