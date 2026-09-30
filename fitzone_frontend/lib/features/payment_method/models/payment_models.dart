import 'package:flutter/material.dart';

/// Métodos de pago disponibles.
enum PayMethod { cash, card, digital }

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.detail,
  });

  final PayMethod id;
  final IconData icon;
  final String label;
  final String detail;
}