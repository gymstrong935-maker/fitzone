import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_text.dart';
import 'fz_field_frame.dart';

/// 70.0 -> "70", 154.3 -> "154.3"
String formatNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class FzNumberField extends StatefulWidget {
  const FzNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.decimal = false,
    this.maxLength = 3,
  });

  final double value;
  final ValueChanged<double> onChanged;

  /// Valor mínimo; se aplica cuando el usuario sale del campo.
  final double min;

  /// Permite un decimal (para el peso).
  final bool decimal;

  /// Máximo de dígitos para campos enteros.
  final int maxLength;

  @override
  State<FzNumberField> createState() => _FzNumberFieldState();
}

class _FzNumberFieldState extends State<FzNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: formatNumber(widget.value));
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant FzNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el valor cambió desde fuera (p. ej. conversión kg/lb), actualiza el
    // texto, salvo que el usuario esté escribiendo.
    if (!_focus.hasFocus && oldWidget.value != widget.value) {
      _setText(formatNumber(widget.value));
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      // Al salir: vacío -> restaura; menor al mínimo -> sube al mínimo.
      final double? parsed = double.tryParse(_controller.text);
      final double next = parsed == null
          ? widget.value
          : (parsed < widget.min ? widget.min : parsed);

      if (next != widget.value) widget.onChanged(next);
      _setText(formatNumber(next));
    }
    if (mounted) setState(() {});
  }

  void _handleChanged(String text) {
    final double? parsed = double.tryParse(text);
    if (parsed != null) widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return FzFieldFrame(
      focused: _focus.hasFocus,
      height: 44,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: widget.decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          if (widget.decimal)
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?'))
          else ...<TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.maxLength),
          ],
        ],
        cursorColor: Colors.white,
        onChanged: _handleChanged,
        style: AppText.body(size: 15, color: Colors.white),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}