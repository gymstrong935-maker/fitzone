import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Botón "píldora" del selector Semanal | Mensual.
class ViewToggleChip extends StatelessWidget {
  const ViewToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.cyanA(0.22) : AppColors.whiteA(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    selected ? AppColors.cyanA(0.40) : AppColors.whiteA(0.10),
              ),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: selected ? AppColors.cyan : AppColors.whiteA(0.5),
                height: 1.43,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}