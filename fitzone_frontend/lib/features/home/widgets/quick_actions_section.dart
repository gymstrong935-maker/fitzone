import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../data/home_data.dart';

/// "Accesos Rápidos": cuadrícula de 2 columnas con 4 tarjetas.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < kQuickActions.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _animated(i)),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < kQuickActions.length
                  ? _animated(i + 1)
                  : const SizedBox(),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Accesos Rápidos', style: AppText.display(size: 16, height: 1.5)),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }

  Widget _animated(int i) {
    final QuickAction action = kQuickActions[i];
    return FadeSlideIn(
      delay: Duration(milliseconds: 200 + i * 50),
      duration: const Duration(milliseconds: 400),
      offsetY: 10,
      child: _QuickActionButton(
        action: action,
        onTap: () => onNavigate(action.id),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({required this.action, required this.onTap});

  final QuickAction action;
  final VoidCallback onTap;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final QuickAction a = widget.action;

    return Semantics(
      button: true,
      label: a.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: PressableScale(
          onTap: widget.onTap,
          pressedScale: 0.94,
          hoverScale: 1.02,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.whiteA(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.whiteA(0.09)),
            ),
            child: Stack(
              children: <Widget>[
                // Tinte cian al pasar el cursor.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hover ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: ColoredBox(color: AppColors.cyanA(0.04)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[a.from, a.to],
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.25),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(a.icon, size: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        a.label,
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.whiteA(0.20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}