import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Encabezado de las sub-pantallas: flecha "volver", título y subtítulo.
class SubScreenHeader extends StatelessWidget {
  const SubScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  /// Variante grande (Nutrición): botón de 40 px y título de 24 px.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final double vertical = large ? 16 : 12;
    final double horizontal = large ? 16 : 20;
    final double buttonSize = large ? 40 : 36;

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        vertical + topInset,
        horizontal,
        vertical,
      ),
      decoration: BoxDecoration(
        color: large ? const Color(0xCC000000) : const Color(0xE6000000),
        border: Border(
          bottom: BorderSide(color: AppColors.whiteA(large ? 0.10 : 0.08)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 512 - 2 * horizontal),
          child: Row(
            children: <Widget>[
              Semantics(
                button: true,
                label: 'Volver',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.whiteA(large ? 0.10 : 0.08),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: large ? 20 : 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: large ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppText.display(
                        size: large ? 24 : 18,
                        weight: FontWeight.w700,
                        height: large ? 1.333 : 1.25,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      SizedBox(height: large ? 0 : 2),
                      Text(
                        subtitle!,
                        style: AppText.body(
                          size: large ? 14 : 12,
                          color: AppColors.whiteA(large ? 0.60 : 0.40),
                          height: large ? 1.43 : 1.333,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marco de las sub-pantallas: encabezado fijo arriba y contenido con scroll.
class SubScreenFrame extends StatelessWidget {
  const SubScreenFrame({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.subtitle,
    this.large = false,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget child;
  final bool large;

  /// Relleno del contenido (el espacio inferior para la barra de navegación
  /// se agrega aparte).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final double bottom = 96 + MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SubScreenHeader(
          title: title,
          subtitle: subtitle,
          onBack: onBack,
          large: large,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Padding(
                  padding: padding + EdgeInsets.only(bottom: bottom),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}