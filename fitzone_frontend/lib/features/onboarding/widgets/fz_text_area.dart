import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'fz_field_frame.dart';

/// Área de texto de varias líneas (empieza con 2 y crece al escribir).
class FzTextArea extends StatefulWidget {
  const FzTextArea({
    super.key,
    required this.initialText,
    required this.hint,
    required this.onChanged,
  });

  final String initialText;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<FzTextArea> createState() => _FzTextAreaState();
}

class _FzTextAreaState extends State<FzTextArea> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
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

  @override
  Widget build(BuildContext context) {
    return FzFieldFrame(
      focused: _focus.hasFocus,
      minHeight: 64,
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        minLines: 2,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        cursorColor: Colors.white,
        onChanged: widget.onChanged,
        style: AppText.body(size: 14, color: Colors.white, height: 1.43),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hint,
          hintStyle: AppText.body(
            size: 14,
            color: AppColors.whiteA(0.30),
            height: 1.43,
          ),
        ),
      ),
    );
  }
}