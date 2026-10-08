import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable_scale.dart';

/// Pantalla temporal de Entrenamiento (la construiremos más adelante).
class WorkoutPlaceholderScreen extends StatelessWidget {
  const WorkoutPlaceholderScreen({
    super.key,
    required this.onComplete,
    required this.onCancel,
  });

  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Entrenamiento',
                    textAlign: TextAlign.center,
                    style: AppText.display(size: 28, letterSpacing: -0.56),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Próximamente',
                    textAlign: TextAlign.center,
                    style: AppText.body(size: 14, color: AppColors.cyan),
                  ),
                  const SizedBox(height: 28),
                  PressableScale(
                    onTap: onComplete,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: <Color>[AppColors.cyan, AppColors.teal],
                        ),
                      ),
                      child: Text(
                        'Finalizar entrenamiento (temporal)',
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancelar',
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
      ),
    );
  }
}