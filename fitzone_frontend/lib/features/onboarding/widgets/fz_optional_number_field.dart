import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'fz_field_frame.dart';
import 'fz_number_field.dart' show formatNumber;

class FzOptionalNumberField extends StatefulWidget {
  const FzOptionalNumberField({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  /// `null` = campo vacío.
  final double? value;
  final String hint;
  final ValueChanged<double?> onChanged;

  @override
  State<FzOptionalNumberField> createState() => _FzOptionalNumberFieldState();
}

class _FzOptionalNumberFieldState extends State<FzOptionalNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    final double? initial = widget.value;
    _controller = TextEditingController(
      text: initial == null ? '' : formatNumber(initial),
    );
    _focus = FocusNode()..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String text) {
    final double? parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed != widget.value) widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return FzFieldFrame(
      focused: _focus.hasFocus,
      height: 36,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d{0,2})?')),
        ],
        cursorColor: Colors.white,
        onChanged: _handleChanged,
        style: AppText.body(size: 14, color: Colors.white),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hint,
          hintStyle: AppText.body(size: 14, color: AppColors.whiteA(0.6)),
        ),
      ),
    );
  }
}