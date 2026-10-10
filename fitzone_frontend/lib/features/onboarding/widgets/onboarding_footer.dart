import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Barra inferior fija: botón "Atrás" (desde el 2.º paso) y "Siguiente".
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.showBack,
    required this.isLast,
    required this.nextEnabled,
    required this.onBack,
    required this.onNext,
  });

  final bool showBack;
  final bool isLast;
  final bool nextEnabled;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            Color(0xFF000000),
            Color(0xF2000000), // negro al 95 %
            Color(0x00000000),
          ],
          stops: <double>[0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Row(
                children: <Widget>[
                  if (showBack) ...<Widget>[
                    _Pressable(
                      onTap: onBack,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.whiteA(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.whiteA(0.15)),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: nextEnabled ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: _Pressable(
                        onTap: nextEnabled ? onNext : null,
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: <Color>[AppColors.cyan, AppColors.teal],
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                isLast ? 'Finalizar configuración' : 'Siguiente',
                                style: AppText.body(
                                  size: 16,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF0A0A0A),
                                ),
                              ),
                              if (!isLast) ...<Widget>[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Envuelve un widget con el efecto de "presionar" (escala 0.97).
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _setPressing(true),
      onTapUp: (_) => _setPressing(false),
      onTapCancel: () => _setPressing(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}