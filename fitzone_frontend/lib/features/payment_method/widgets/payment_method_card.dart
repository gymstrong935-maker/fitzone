import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/payment_models.dart';

/// Tarjeta seleccionable de un método de pago.
class PaymentMethodCard extends StatefulWidget {
  const PaymentMethodCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<PaymentMethodCard> {
  bool _pressing = false;

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.isSelected;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.option.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressing(true),
        onTapUp: (_) => _setPressing(false),
        onTapCancel: () => _setPressing(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressing ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.cyanA(0.09) : AppColors.whiteA(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.cyan : AppColors.whiteA(0.10),
                width: 1.5,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(color: AppColors.cyanA(0.14), blurRadius: 20),
                    ]
                  : <BoxShadow>[],
            ),
            child: Row(
              children: <Widget>[
                _buildIconBox(selected),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.option.label,
                        style: AppText.display(
                          size: 15.2,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.option.detail,
                        style: AppText.body(
                          size: 12.48,
                          color: AppColors.whiteA(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _buildIndicator(selected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.cyanA(0.25), AppColors.tealA(0.15)],
              )
            : null,
        color: selected ? null : AppColors.whiteA(0.07),
        border: Border.all(
          color: selected ? AppColors.cyanA(0.35) : AppColors.whiteA(0.08),
        ),
      ),
      child: Icon(
        widget.option.icon,
        size: 20,
        color: selected ? AppColors.cyan : AppColors.whiteA(0.55),
      ),
    );
  }

  Widget _buildIndicator(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.cyan, AppColors.teal],
              )
            : null,
        border: selected
            ? null
            : Border.all(color: AppColors.whiteA(0.2), width: 1.5),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: Color(0xFF0A0A0A),
            )
          : null,
    );
  }
}