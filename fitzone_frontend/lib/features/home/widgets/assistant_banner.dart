import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable_scale.dart';

/// Tarjeta que abre el asistente con IA.
class AssistantBanner extends StatelessWidget {
  const AssistantBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir el asistente FitZone',
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.98,
        hoverScale: 1.01,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.fromRGBO(124, 58, 237, 0.16),
                Color.fromRGBO(6, 182, 212, 0.10),
              ],
            ),
            border: Border.all(color: const Color.fromRGBO(124, 58, 237, 0.30)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF7C3AED), AppColors.cyan],
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Asistente FitZone',
                      style: AppText.display(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pregúntame por planes, entrenadores, horarios y tu cuenta',
                      style: AppText.body(
                        size: 12,
                        color: AppColors.whiteA(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.whiteA(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}