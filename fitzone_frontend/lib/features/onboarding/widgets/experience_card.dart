import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/experience_level.dart';

/// Tarjeta seleccionable de un nivel de experiencia.
class ExperienceCard extends StatefulWidget {
  const ExperienceCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ExperienceOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  static const Color _cyan400 = Color(0xFF22D3EE);

  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final ExperienceOption o = widget.option;
    final bool selected = widget.isSelected;

    return Semantics(
      button: true,
      selected: selected,
      label: o.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressing(true),
        onTapUp: (_) => _setPressing(false),
        onTapCancel: () => _setPressing(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressing ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: selected ? AppColors.cyanA(0.09) : AppColors.whiteA(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.cyan : AppColors.whiteA(0.10),
                width: 1.5,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(color: AppColors.cyanA(0.12), blurRadius: 20),
                    ]
                  : <BoxShadow>[],
            ),
            child: Row(
              children: <Widget>[
                // Recuadro con degradado, borde y emoji.
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        AppColors.cyanA(0.20),
                        AppColors.tealA(0.20),
                      ],
                    ),
                    border: Border.all(color: AppColors.cyanA(0.25)),
                  ),
                  child: Text(o.icon, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              o.title,
                              style: AppText.display(
                                size: 18,
                                weight: FontWeight.w700,
                                height: 1.556,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyanA(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              o.reps,
                              style: AppText.body(
                                size: 14,
                                weight: FontWeight.w600,
                                color: _cyan400,
                                height: 1.43,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        o.description,
                        style: AppText.body(
                          size: 14,
                          color: AppColors.whiteA(0.55),
                          height: 1.43,
                        ),
                      ),
                    ],
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