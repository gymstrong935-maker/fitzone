import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Botón flotante de soporte (abre el chatbot).
class SupportFab extends StatefulWidget {
  const SupportFab({super.key, required this.onTap});

  final VoidCallback onTap;

  /// El globo de ayuda solo se muestra una vez por sesión.
  static bool _hintShown = false;

  @override
  State<SupportFab> createState() => _SupportFabState();
}

class _SupportFabState extends State<SupportFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _showTimer;
  Timer? _hideTimer;
  bool _hint = false;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();

    if (!SupportFab._hintShown) {
      _showTimer = Timer(const Duration(milliseconds: 3000), () {
        if (!mounted) return;
        SupportFab._hintShown = true;
        setState(() => _hint = true);
        _hideTimer = Timer(const Duration(seconds: 7), () {
          if (mounted) setState(() => _hint = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _tap() {
    setState(() => _hint = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: _hint
              ? GestureDetector(
                  key: const ValueKey<String>('hint'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cyanA(0.35)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: AppColors.cyanA(0.18), blurRadius: 18),
                      ],
                    ),
                    child: Text(
                      '¿Necesitas ayuda?',
                      style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey<String>('no-hint')),
        ),
        Semantics(
          button: true,
          label: 'Abrir soporte',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _pressing = true),
              onTapUp: (_) => setState(() => _pressing = false),
              onTapCancel: () => setState(() => _pressing = false),
              onTap: _tap,
              child: AnimatedScale(
                scale: _pressing ? 0.92 : 1,
                duration: const Duration(milliseconds: 120),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (BuildContext context, Widget? _) {
                          final double e = Curves.easeOut.transform(_pulse.value);
                          return Opacity(
                            opacity: 0.55 * (1 - e),
                            child: Transform.scale(
                              scale: 1 + 0.7 * e,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.cyan, width: 1.5),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[AppColors.cyan, AppColors.teal],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.cyanA(0.40),
                              blurRadius: 22,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          size: 28,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}