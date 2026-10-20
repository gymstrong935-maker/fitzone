import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

/// Mantiene los colores originales de una foto en modo claro.
class FzImageFix extends StatelessWidget {
  const FzImageFix({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (BuildContext context, Widget? _) {
        if (!ThemeController.instance.isLight) return child;
        return ColorFiltered(
          colorFilter: ThemeController.counterFor(1),
          child: child,
        );
      },
    );
  }
}