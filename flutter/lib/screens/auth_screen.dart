import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN / REGISTRO
  // ============================================================

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      showMessage('Completa tu correo electrónico.');
      return;
    }

    if (password.isEmpty) {
      showMessage('Completa tu contraseña.');
      return;
    }

    final auth = context.read<AuthProvider>();

    String? error;

    if (isLogin) {
      // ----------------------------------------------------------
      // LOGIN
      // ----------------------------------------------------------
      error = await auth.login(
        email: email,
        password: password,
      );
    } else {
      // ----------------------------------------------------------
      // REGISTRO
      // ----------------------------------------------------------
      final nombre = nameController.text.trim();
      final telefono = phoneController.text.trim();

      if (nombre.isEmpty) {
        showMessage('Escribe tu nombre.');
        return;
      }

      error = await auth.register(
        nombre: nombre,
        email: email,
        password: password,
        telefono: telefono,
      );
    }

    if (!mounted) return;

    // ------------------------------------------------------------
    // ERROR DEL BACKEND
    // ------------------------------------------------------------

    if (error != null) {
      showMessage(error);
      return;
    }

    // ------------------------------------------------------------
    // LOGIN EXITOSO
    // ------------------------------------------------------------

    if (isLogin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );

      return;
    }

    // ------------------------------------------------------------
    // REGISTRO EXITOSO
    // ------------------------------------------------------------

    showMessage(
      'Registro exitoso. Revisa tu correo para verificar la cuenta.',
    );

    setState(() {
      isLogin = true;
      passwordController.clear();
    });
  }

  // ============================================================
  // RECUPERAR CONTRASEÑA
  // ============================================================

  void openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  // ============================================================
  // CAMBIAR LOGIN / REGISTRO
  // ============================================================

  void toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      passwordController.clear();
    });
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            50,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // LOGO
              // ==================================================

              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cyan,
                    ),
                    gradient: const RadialGradient(
                      colors: [
                        Color(0x4406B6D4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.cyanLight,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // NOMBRE FITZONE
              // ==================================================

              Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: 'Fit',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: 'Zone',
                        style: TextStyle(
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 45),

              // ==================================================
              // TITULO
              // ==================================================

              Text(
                isLogin
                    ? 'Bienvenido de nuevo'
                    : 'Crea tu cuenta',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // SUBTITULO
              // ==================================================

              Text(
                isLogin
                    ? 'Continúa trabajando en tu mejor versión.'
                    : 'Empieza hoy tu transformación.',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // CAMPOS DE REGISTRO
              // ==================================================

              if (!isLogin) ...[
                const Text(
                  'Nombre',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Teléfono',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Tu teléfono',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                  ),
                ),

                const SizedBox(height: 18),
              ],

              // ==================================================
              // CORREO
              // ==================================================

              const Text(
                'Correo electrónico',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'correo@ejemplo.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CONTRASEÑA
              // ==================================================

              const Text(
                'Contraseña',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!loading) {
                    submit();
                  }
                },
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // OLVIDÉ MI CONTRASEÑA
              // ==================================================

              if (isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading
                        ? null
                        : openForgotPassword,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // ==================================================
              // BOTÓN PRINCIPAL
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          isLogin
                              ? 'Iniciar sesión'
                              : 'Crear cuenta',
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // DIVISOR
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: Colors.white12,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    child: Text(
                      isLogin
                          ? '¿Nuevo en FitZone?'
                          : '¿Ya tienes cuenta?',
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color: Colors.white12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // CAMBIAR ENTRE LOGIN / REGISTRO
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: loading
                      ? null
                      : toggleAuthMode,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      52,
                    ),
                    side: const BorderSide(
                      color: Colors.white24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isLogin
                        ? 'Crear una cuenta'
                        : 'Iniciar sesión',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}