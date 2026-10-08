import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class _NavTab {
  const _NavTab(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

const List<_NavTab> _tabs = <_NavTab>[
  _NavTab('home', 'Inicio', Icons.home_rounded),
  _NavTab('stats', 'Estadísticas', Icons.bar_chart_rounded),
  _NavTab('plan', 'Mi Plan', Icons.calendar_today_rounded),
  _NavTab('settings', 'Ajustes', Icons.settings_rounded),
];

/// Barra de navegación inferior (cristal esmerilado + línea brillante arriba).
class FzBottomNav extends StatelessWidget {
  const FzBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  final String activeTab;
  final ValueChanged<String> onTabChange;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xEB050505),
            border: Border(top: BorderSide(color: AppColors.whiteA(0.09))),
          ),
          child: Stack(
            children: <Widget>[
              // Línea brillante superior.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        const Color(0x0006B6D4),
                        AppColors.cyanA(0.35),
                        AppColors.tealA(0.35),
                        AppColors.cyanA(0.35),
                        const Color(0x0006B6D4),
                      ],
                      stops: const <double>[0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          for (final _NavTab tab in _tabs)
                            _NavButton(
                              tab: tab,
                              isActive: activeTab == tab.id,
                              onTap: () => onTabChange(tab.id),
                            ),
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
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? AppColors.cyan : AppColors.whiteA(0.45);

    return Semantics(
      button: true,
      selected: isActive,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56),
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              // Fondo "píldora" de la pestaña activa.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: isActive ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: AnimatedScale(
                      scale: isActive ? 1 : 0.9,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              AppColors.cyanA(0.18),
                              AppColors.tealA(0.10),
                            ],
                          ),
                          border: Border.all(color: AppColors.cyanA(0.22)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Ícono + punto brillante.
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: <Widget>[
                          AnimatedScale(
                            scale: isActive ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: TweenAnimationBuilder<Color?>(
                              tween: ColorTween(end: iconColor),
                              duration: const Duration(milliseconds: 200),
                              builder: (
                                BuildContext context,
                                Color? color,
                                Widget? _,
                              ) {
                                return Icon(
                                  tab.icon,
                                  size: 22,
                                  color: color,
                                  shadows: isActive
                                      ? <Shadow>[
                                          Shadow(
                                            color: AppColors.cyanA(0.55),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: -6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: AnimatedScale(
                                scale: isActive ? 1 : 0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.cyan,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color:
                                            AppColors.cyanA(0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Etiqueta.
                    AnimatedOpacity(
                      opacity: isActive ? 1 : 0.45,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        tab.label,
                        style: isActive
                            ? AppText.display(
                                size: 10.72,
                                weight: FontWeight.w500,
                                color: AppColors.cyan,
                                letterSpacing: 0.107,
                                height: 1,
                              ).copyWith(
                                shadows: <Shadow>[
                                  Shadow(
                                    color: AppColors.cyanA(0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              )
                            : AppText.body(
                                size: 10.72,
                                weight: FontWeight.w500,
                                color: AppColors.whiteA(0.45),
                                height: 1,
                              ),
                      ),
                    ),
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