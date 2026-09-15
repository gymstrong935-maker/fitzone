import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/fitzone_button.dart';
import '../../widgets/fitzone_logo.dart';
import '../../widgets/fitzone_text_field.dart';
import '../../widgets/fitzone_title.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa todos los campos',
          ),
        ),
      );

      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final respuesta = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respuesta['mensaje']?.toString() ??
                'Inicio de sesión correcto',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  void _recuperarPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Aquí abriremos Recuperar contraseña',
        ),
      ),
    );
  }

  void _crearCuenta() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Aquí abriremos el registro',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 25),

              const FitZoneLogo(
                size: 85,
              ),

              const SizedBox(height: 25),

              const FitZoneTitle(
                title: 'Iniciar sesión',
                subtitle: 'Ingresa a tu cuenta FitZone',
              ),

              const SizedBox(height: 40),

              FitZoneTextField(
                label: 'Correo electrónico',
                hintText: 'Ingresa tu correo',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              FitZoneTextField(
                label: 'Contraseña',
                hintText: 'Ingresa tu contraseña',
                icon: Icons.lock_outline,
                obscureText: true,
                controller: _passwordController,
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _recuperarPassword,
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Color(0xFF05C8D8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FitZoneButton(
                text: _cargando
                    ? 'CONECTANDO...'
                    : 'INICIAR SESIÓN',
                onPressed: _cargando
                    ? null
                    : _iniciarSesion,
              ),

              const SizedBox(height: 25),

              Row(
                children: const [
                  Expanded(
                    child: Divider(
                      color: Colors.white24,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                    ),
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                '¿Todavía no tienes una cuenta?',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 10),

              FitZoneButton(
                text: 'CREAR CUENTA',
                onPressed: _crearCuenta,
                outlined: true,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}