import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_text.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/models/auth_models.dart';
import 'features/payment_method/models/payment_models.dart';
import 'features/payment_method/payment_method_screen.dart';
import 'features/plan_selection/models/plan.dart';
import 'features/plan_selection/plan_selection_screen.dart';

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

/// Etapas del flujo previo a la app principal (igual que en el diseño).
enum AppStage {
  planSelection,
  auth,
  paymentMethod,
  paymentValidation,
  onboarding,
}

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  AppStage _stage = AppStage.planSelection;
  PlanId? _selectedPlan;
  AuthUser? _user;
  PayMethod? _paymentMethod;

  void _goTo(AppStage stage) => setState(() => _stage = stage);

  void _handleSelectPlan(PlanId plan) {
    setState(() {
      _selectedPlan = plan;
      // Gratis -> Onboarding. Mensual/Anual -> Auth.
      _stage = plan == PlanId.free ? AppStage.onboarding : AppStage.auth;
    });
  }

  void _handleAuthSuccess(AuthUser user) {
    setState(() {
      _user = user;
      _stage = AppStage.paymentMethod;
    });
  }

  void _handlePaymentMethodSelected(PayMethod method) {
    setState(() {
      _paymentMethod = method;
      _stage = AppStage.paymentValidation;
    });
  }

  Widget _buildStage() {
    final ValueKey<AppStage> key = ValueKey<AppStage>(_stage);

    switch (_stage) {
      case AppStage.planSelection:
        return PlanSelectionScreen(key: key, onSelectPlan: _handleSelectPlan);

      case AppStage.auth:
        return AuthScreen(
          key: key,
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
          title: 'Validación de pago',
          message:
              'Método elegido: ${_paymentMethod?.name ?? '-'}\nUsuario: ${_user?.email ?? '-'}',
          onBack: () => _goTo(AppStage.paymentMethod),
          onNext: () => _goTo(AppStage.onboarding),
        );

      case AppStage.onboarding:
        return _PlaceholderScreen(
          key: key,
          title: 'Onboarding',
          message: 'Plan: ${_selectedPlan?.name ?? '-'}',
          onBack: () => _goTo(AppStage.planSelection),
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

/// Pantalla temporal para las etapas que todavía no hemos construido.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onBack,
    this.onNext,
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: AppText.display(size: 28)),
                const SizedBox(height: 8),
                Text(
                  'Próximamente',
                  style: AppText.body(size: 14, color: AppColors.cyan),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 13, color: AppColors.whiteA(0.55)),
                ),
                const SizedBox(height: 24),
                if (onNext != null)
                  TextButton(
                    onPressed: onNext,
                    child: Text(
                      'Continuar (temporal)',
                      style: AppText.body(size: 14, color: AppColors.cyan),
                    ),
                  ),
                TextButton(
                  onPressed: onBack,
                  child: Text(
                    'Volver',
                    style: AppText.body(
                      size: 14,
                      color: AppColors.whiteA(0.6),
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