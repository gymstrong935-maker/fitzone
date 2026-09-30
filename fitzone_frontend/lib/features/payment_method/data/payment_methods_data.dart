import 'package:flutter/material.dart';

import '../models/payment_models.dart';

const List<PaymentMethodOption> kPaymentMethods = <PaymentMethodOption>[
  PaymentMethodOption(
    id: PayMethod.cash,
    icon: Icons.payments_outlined,
    label: 'Efectivo',
    detail: 'Pago presencial en puntos autorizados',
  ),
  PaymentMethodOption(
    id: PayMethod.card,
    icon: Icons.credit_card_outlined,
    label: 'Tarjeta débito / crédito',
    detail: 'Visa, Mastercard y tarjetas locales',
  ),
  PaymentMethodOption(
    id: PayMethod.digital,
    icon: Icons.smartphone_outlined,
    label: 'Digital',
    detail: 'Nequi y otros medios digitales',
  ),
];