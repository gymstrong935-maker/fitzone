import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class FzFieldFrame extends StatelessWidget {
  const FzFieldFrame({
    super.key,
    required this.focused,
    required this.child,
    this.height,
    this.minHeight = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.alignment = Alignment.centerLeft,
  });

  final bool focused;
  final Widget child;
  final double? height;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  static const double radius = 18;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Anillo de foco (3 px por fuera del campo).
        Positioned(
          left: -3,
          top: -3,
          right: -3,
          bottom: -3,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: focused ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius + 3),
                  border: Border.all(color: AppColors.cyanA(0.5), width: 3),
                ),
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: focused ? AppColors.cyan : AppColors.whiteA(0.15),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}