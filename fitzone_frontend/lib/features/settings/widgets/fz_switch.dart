import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Interruptor: encendido = pista cian con botón oscuro; apagado = pista
/// gris translúcida con botón claro.
class FzSwitch extends StatelessWidget {
  const FzSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 32,
              height: 18.4,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.cyan
                    : const Color.fromRGBO(0, 0, 0, 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xF2FFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}