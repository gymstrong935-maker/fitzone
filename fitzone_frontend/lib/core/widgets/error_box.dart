import 'package:flutter/material.dart';

import '../theme/app_text.dart';

/// Recuadro rojo con un mensaje de error.
class ErrorBox extends StatelessWidget {
  const ErrorBox(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(239, 68, 68, 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.22)),
      ),
      child: Text(
        message,
        style: AppText.body(size: 12, color: const Color(0xFFF87171)),
      ),
    );
  }
}