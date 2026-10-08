import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Pantalla temporal de las secciones que todavía no hemos construido.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    this.onBack,
  });

  final String title;
  final IconData icon;

  /// Si se indica, muestra el botón "Volver al inicio" (sub-pantallas).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cyanA(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cyanA(0.25)),
                ),
                child: Icon(icon, size: 28, color: AppColors.cyanLight),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppText.display(size: 24, letterSpacing: -0.48)),
              const SizedBox(height: 4),
              Text(
                'Próximamente',
                style: AppText.body(size: 14, color: AppColors.cyan),
              ),
              if (onBack != null) ...<Widget>[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onBack,
                  child: Text(
                    'Volver al inicio',
                    style: AppText.body(
                      size: 14,
                      color: AppColors.whiteA(0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}