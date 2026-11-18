import 'dart:typed_data';

import '../api/api_client.dart';
import 'backend_models.dart';

class PaymentsService {
  PaymentsService(this._api);

  final ApiClient _api;

  /// Pagos del usuario, el más reciente primero.
  Future<List<BackendPayment>> mine({String? estado}) async {
    final dynamic data = await _api.get(
      '/api/payments/mios${estado == null ? '' : '?estado=$estado'}',
    );
    final List<dynamic> list = data is List ? data : const <dynamic>[];
    return <BackendPayment>[
      for (final dynamic p in list)
        if (p is Map<String, dynamic>) BackendPayment.fromJson(p),
    ];
  }

  /// Pago pendiente de suscripción (el que debe completar el usuario).
  Future<BackendPayment?> pendingSubscriptionPayment() async {
    final List<BackendPayment> all = await mine(estado: 'pendiente');
    for (final BackendPayment p in all) {
      if (p.tipo == 'suscripcion') return p;
    }
    return null;
  }

  /// Registra cómo paga el usuario. Con `Pago digital` hay que subir la factura.
  Future<void> submit({
    required String paymentId,
    required String method,
    Uint8List? receiptBytes,
    String? receiptName,
    String? reference,
  }) async {
    await _api.multipart(
      'PUT',
      '/api/payments/$paymentId/comprobante',
      fields: <String, String>{
        'metodoPago': method,
        if (reference != null && reference.trim().isNotEmpty)
          'referencia': reference.trim(),
      },
      fileField: receiptBytes == null ? null : 'comprobante',
      bytes: receiptBytes,
      filename: receiptName,
    );
  }
}
