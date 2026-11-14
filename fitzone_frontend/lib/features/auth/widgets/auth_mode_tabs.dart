import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/auth_models.dart';

/// Selector "Ingresar | Registro".
class AuthModeTabs extends StatelessWidget {
  const AuthModeTabs({super.key, required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.07)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Tab(
              label: 'Ingresar',
              selected: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Tab(
              label: 'Registro',
              selected: mode == AuthMode.register,
              onTap: () => onChanged(AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: <Color>[AppColors.cyan, AppColors.teal],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.cyanA(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            height: 1.5,
            color: selected ? AppColors.background : AppColors.whiteA(0.45),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}