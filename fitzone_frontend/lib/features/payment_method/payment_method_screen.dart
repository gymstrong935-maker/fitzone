import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ellipse_glow.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/shimmer_top_bar.dart';
import 'data/payment_methods_data.dart';
import 'models/payment_models.dart';
import 'widgets/payment_method_card.dart';

/// Imagen del código QR Bre-B universal. Solo hay que reemplazar este archivo
/// (mismo nombre) por tu QR real y volver a ejecutar la app.
const String kBreBQrAsset = 'assets/images/qr_breb.png';

/// Pantalla de pago: elegir Efectivo o Pago digital.
/// Con pago digital muestra el QR Bre-B y pide la imagen de la factura.
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({
    super.key,
    required this.label,
    required this.amount,
    required this.onSubmit,
    required this.onBack,
    this.heading = 'Método de pago',
    this.subtitle = 'Selecciona cómo quieres pagar',
    this.note = 'Tu pago será validado por el equipo de FitZone. '
        'Cuando lo confirmen, recibirás una notificación.',
  });

  /// Etiqueta superior (por ejemplo "PLAN MENSUAL" o "CAMBIO DE ENTRENADOR").
  final String label;

  /// Valor que se debe pagar, en pesos.
  final double amount;

  final String heading;
  final String subtitle;
  final String note;

  /// Se llama al pulsar "Confirmar". Si lanza [ApiException] se muestra el
  /// mensaje y se puede reintentar.
  final Future<void> Function(PayMethod method, Uint8List? receipt, String? receiptName)
      onSubmit;
  final VoidCallback onBack;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PayMethod? _selected;
  Uint8List? _receipt;
  String? _receiptName;
  bool _confirming = false;
  String _error = '';

  bool get _ready {
    if (_selected == null) return false;
    if (_selected == PayMethod.digital) return _receipt != null;
    return true;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        setState(() => _error = 'La imagen supera los 5 MB. Elige una más liviana.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _receipt = bytes;
        _receiptName = file.name;
        _error = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo abrir la imagen. Revisa los permisos de la app.');
    }
  }

  Future<void> _submit() async {
    final PayMethod? method = _selected;
    if (method == null || !_ready || _confirming) return;

    setState(() {
      _confirming = true;
      _error = '';
    });

    try {
      await widget.onSubmit(
        method,
        method == PayMethod.digital ? _receipt : null,
        method == PayMethod.digital ? _receiptName : null,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: EllipseGlow(
              color: AppColors.cyanA(0.09),
              centerX: 0.5,
              centerY: 0.15,
              radiusX: 0.55,
              radiusY: 0.40,
              fadeStop: 0.65,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(onTap: widget.onBack),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        duration: const Duration(milliseconds: 450),
                        offsetY: 20,
                        child: _buildHeader(),
                      ),
                      const SizedBox(height: 20),
                      _AmountCard(amount: widget.amount),
                      const SizedBox(height: 20),
                      for (int i = 0; i < kPaymentMethods.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: 12),
                        FadeSlideIn(
                          delay: Duration(milliseconds: 100 + i * 80),
                          duration: const Duration(milliseconds: 450),
                          offsetY: 20,
                          child: PaymentMethodCard(
                            option: kPaymentMethods[i],
                            isSelected: _selected == kPaymentMethods[i].id,
                            onTap: () {
                              if (_confirming) return;
                              setState(() {
                                _selected = kPaymentMethods[i].id;
                                _error = '';
                              });
                            },
                          ),
                        ),
                      ],
                      if (_selected == PayMethod.digital) ...<Widget>[
                        const SizedBox(height: 20),
                        _buildDigital(),
                      ],
                      if (_selected == PayMethod.cash) ...<Widget>[
                        const SizedBox(height: 20),
                        _InfoBox(
                          icon: Icons.storefront_outlined,
                          text: 'Paga ${formatCop(widget.amount)} en efectivo en el '
                              'gimnasio. El equipo confirmará tu pago en la app.',
                        ),
                      ],
                      const SizedBox(height: 20),
                      _InfoBox(icon: Icons.info_outline_rounded, text: widget.note),
                      if (_error.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        ErrorBox(_error),
                      ],
                      const SizedBox(height: 22),
                      _ContinueButton(
                        enabled: _ready,
                        confirming: _confirming,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: ShimmerTopBar()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyanA(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cyanA(0.25)),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w600,
              color: AppColors.cyanText,
              letterSpacing: 0.92,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.heading,
          style: AppText.display(size: 28, letterSpacing: -0.56, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          style: AppText.body(size: 14, color: AppColors.whiteA(0.5)),
        ),
      ],
    );
  }

  // ── Pago digital: QR Bre-B + factura ─────────────────────────────────────
  Widget _buildDigital() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.whiteA(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepTitle(number: '1', text: 'Escanea el QR y paga ${formatCop(widget.amount)}'),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 230,
              height: 230,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white, // el QR siempre sobre blanco para que lo lean las apps
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.cyanA(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Image.asset(
                kBreBQrAsset,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) => Center(
                  child: Text(
                    'Aquí va tu QR Bre-B\n($kBreBQrAsset)',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 12.5,
                      color: AppColors.onAccent.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'QR Bre-B universal: funciona desde cualquier banco o billetera.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 12.5, color: AppColors.whiteA(0.5), height: 1.45),
          ),
          const SizedBox(height: 20),
          _StepTitle(number: '2', text: 'Sube la factura o comprobante'),
          const SizedBox(height: 12),
          if (_receipt != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(_receipt!, height: 190, fit: BoxFit.cover),
            ),
          if (_receipt != null) const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _PickButton(
                  icon: Icons.photo_library_outlined,
                  label: _receipt == null ? 'Galería' : 'Cambiar',
                  onTap: _confirming ? null : () => _pick(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Cámara',
                  onTap: _confirming ? null : () => _pick(ImageSource.camera),
                ),
              ),
            ],
          ),
          if (_receipt == null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Necesitamos la factura para validar tu pago.',
              style: AppText.body(size: 12, color: AppColors.amber),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanA(0.22)),
      ),
      child: Row(
        children: <Widget>[
          Text('Total a pagar', style: AppText.body(size: 14, color: AppColors.whiteA(0.6))),
          const Spacer(),
          Text(
            formatCop(amount),
            style: AppText.display(size: 22, color: AppColors.cyanText),
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: <Color>[AppColors.cyan, AppColors.teal]),
          ),
          child: Text(
            number,
            style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.onAccent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppText.body(size: 14, weight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanA(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.cyanText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppText.body(size: 12.8, color: AppColors.whiteA(0.6), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.whiteA(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.whiteA(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.cyanText),
            const SizedBox(width: 8),
            Text(label, style: AppText.body(size: 14, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.whiteA(0.5)),
              const SizedBox(width: 6),
              Text('Volver', style: AppText.body(size: 14, color: AppColors.whiteA(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón "Confirmar": gris hasta que el pago está completo.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.confirming,
    required this.onTap,
  });

  final bool enabled;
  final bool confirming;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool clickable = enabled && !confirming;
    final Color content = enabled ? AppColors.onAccent : AppColors.whiteA(0.3);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: clickable ? onTap : null,
      child: AnimatedOpacity(
        opacity: confirming ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? const LinearGradient(colors: <Color>[AppColors.cyan, AppColors.teal])
                : null,
            color: enabled ? null : AppColors.whiteA(0.06),
            border: enabled ? null : Border.all(color: AppColors.whiteA(0.10)),
            boxShadow: enabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.cyanA(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                confirming ? 'Enviando...' : 'Confirmar pago',
                style: AppText.body(size: 15.2, weight: FontWeight.w600, color: content),
              ),
              if (!confirming) ...<Widget>[
                const SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 18, color: content),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
