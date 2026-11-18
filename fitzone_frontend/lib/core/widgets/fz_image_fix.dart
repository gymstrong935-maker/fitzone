import 'package:flutter/material.dart';

/// Antes devolvía a las fotos su color original cuando el modo claro se hacía
/// con un filtro de inversión. Con el tema claro real ya no hace falta, pero se
/// conserva para no tocar los sitios donde se usa.
class FzImageFix extends StatelessWidget {
  const FzImageFix({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
