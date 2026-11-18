import 'package:flutter/material.dart';

import '../models/payment_models.dart';

/// Solo se aceptan dos formas de pago.
const List<PaymentMethodOption> kPaymentMethods = <PaymentMethodOption>[
  PaymentMethodOption(
    id: PayMethod.cash,
    icon: Icons.payments_outlined,
    label: 'Efectivo',
    detail: 'Pago presencial en el gimnasio',
  ),
  PaymentMethodOption(
    id: PayMethod.digital,
    icon: Icons.qr_code_2_rounded,
    label: 'Pago digital',
    detail: 'Escanea el QR Bre-B y sube tu factura',
  ),
];
