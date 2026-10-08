import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Campo de texto con ícono, borde que cambia según foco/relleno y anillo de foco.
class FancyInput extends StatefulWidget {
  const FancyInput({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<FancyInput> createState() => _FancyInputState();
}

class _FancyInputState extends State<FancyInput> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focus.hasFocus;
    final bool filled = widget.controller.text.isNotEmpty;

    final Color background = focused
        ? AppColors.cyanA(0.07)
        : filled
            ? AppColors.whiteA(0.06)
            : AppColors.whiteA(0.05);

    final Color borderColor = focused
        ? AppColors.cyan
        : filled
            ? AppColors.cyanA(0.3)
            : AppColors.whiteA(0.10);

    final Color iconColor = focused
        ? AppColors.cyan
        : filled
            ? AppColors.cyanA(0.6)
            : AppColors.whiteA(0.30);

    return SizedBox(
      height: 52,
      child: Stack(
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
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: AppColors.cyanA(0.10), width: 3),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: <Widget>[
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: iconColor),
                    duration: const Duration(milliseconds: 200),
                    builder: (BuildContext context, Color? color, Widget? _) {
                      return Icon(widget.icon, size: 16, color: color);
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      obscureText: widget.obscureText,
                      obscuringCharacter: '•',
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      autofillHints: widget.autofillHints,
                      onSubmitted: widget.onSubmitted,
                      cursorColor: Colors.white,
                      style: AppText.body(size: 14.72, color: Colors.white),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: widget.hint,
                        hintStyle: AppText.body(
                          size: 14.72,
                          color: AppColors.whiteA(0.30),
                        ),
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...<Widget>[
                    const SizedBox(width: 12),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}