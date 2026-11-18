import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../admin_controller.dart';
import '../widgets/admin_widgets.dart';

/// Cambios de entrenador: el admin valida la solicitud y, si hay diferencia de
/// precio, también el pago (con su factura).
class AdminCoachChangesScreen extends StatefulWidget {
  const AdminCoachChangesScreen({super.key, required this.service, required this.controller});

  final AdminService service;
  final AdminController controller;

  @override
  State<AdminCoachChangesScreen> createState() => _AdminCoachChangesScreenState();
}

class _AdminCoachChangesScreenState extends State<AdminCoachChangesScreen> {
  String _estado = 'pendiente';
  int _version = 0;
  String? _busyId;

  Future<void> _approve(Map<String, dynamic> change) async {
    final String id = str(change['_id']);
    final String user = str(asMap(change['usuarioId'])['nombre']);
    final String to = str(asMap(change['entrenadorNuevoId'])['nombre']);
    final num diff = asNum(change['diferencia']);

    final bool ok = await adminConfirm(
      context,
      title: '¿Aprobar el cambio?',
      message: diff > 0
          ? '$user pasará a entrenar con $to y se dará por validado el pago de ${formatCop(diff)}.'
          : '$user pasará a entrenar con $to (sin costo adicional).',
      confirmLabel: 'Aprobar',
      danger: false,
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = id);
    try {
      await widget.service.approveCoachChange(id);
      if (!mounted) return;
      adminToast(context, 'Cambio aprobado: $user ahora entrena con $to');
      widget.controller.refresh(silent: true);
      setState(() => _version++);
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(Map<String, dynamic> change) async {
    final String id = str(change['_id']);
    final String? reason = await _askReason();
    if (reason == null || !mounted) return;

    setState(() => _busyId = id);
    try {
      await widget.service.rejectCoachChange(id, reason: reason);
      if (!mounted) return;
      adminToast(context, 'Cambio rechazado');
      widget.controller.refresh(silent: true);
      setState(() => _version++);
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  /// Pide un motivo opcional. `null` = canceló.
  Future<String?> _askReason() {
    final TextEditingController controller = TextEditingController();
    return showAdminSheet<String>(
      context,
      (BuildContext ctx) => AdminSheet(
        title: 'Rechazar el cambio',
        subtitle: 'Si quieres, cuéntale el motivo al usuario',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AdminTextField(
              label: 'Motivo (opcional)',
              controller: controller,
              maxLength: 200,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            AdminButton(
              label: 'Rechazar cambio',
              icon: Icons.close_rounded,
              kind: AdminButtonKind.danger,
              onTap: () => Navigator.of(ctx).pop(controller.text.trim()),
            ),
            const SizedBox(height: 10),
            AdminButton(label: 'Volver', onTap: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Cambios de entrenador',
      subtitle: 'Valida los cambios y los pagos de diferencia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminChoiceChips<String>(
            options: const <(String, String)>[
              ('pendiente', 'Por validar'),
              ('pendiente_pago', 'Esperando pago'),
              ('aprobada', 'Aprobados'),
              ('rechazada', 'Rechazados'),
              ('', 'Todos'),
            ],
            selected: _estado,
            onChanged: (String v) => setState(() => _estado = v),
          ),
          const SizedBox(height: 18),
          AdminFuture<List<Map<String, dynamic>>>(
            key: ValueKey<String>('$_estado|$_version'),
            load: () => widget.service.coachChanges(estado: _estado),
            builder: (BuildContext context, List<Map<String, dynamic>> list,
                Future<void> Function() reload) {
              if (list.isEmpty) {
                return const AdminEmpty(
                  icon: Icons.swap_horiz_rounded,
                  title: 'No hay solicitudes aquí',
                  message: 'Cuando un usuario pida cambiar de entrenador aparecerá en esta lista.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < list.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 12),
                    _ChangeCard(
                      change: list[i],
                      busy: _busyId == str(list[i]['_id']),
                      onApprove: () => _approve(list[i]),
                      onReject: () => _reject(list[i]),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({
    required this.change,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> change;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = asMap(change['usuarioId']);
    final Map<String, dynamic> from = asMap(change['entrenadorActualId']);
    final Map<String, dynamic> to = asMap(change['entrenadorNuevoId']);
    final Map<String, dynamic> payment = asMap(change['pagoId']);
    final String estado = str(change['estado']);
    final num diff = asNum(change['diferencia']);
    final bool pending = estado == 'pendiente';
    final String receipt = str(payment['comprobanteUrl']);
    final String method = str(payment['metodoPago']);

    return AdminCard(
      highlight: pending ? const Color.fromRGBO(251, 191, 36, 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      str(user['nombre']).isEmpty ? 'Usuario eliminado' : str(user['nombre']),
                      style: AppText.display(size: 16, height: 1.4),
                    ),
                    Text(
                      str(user['email']),
                      style: AppText.body(size: 12.5, color: AppColors.whiteA(0.45)),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: statusLabel(estado), color: statusColor(estado)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: _Coach('Actual', str(from['nombre']), asNum(change['precioActual']))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.cyanText),
              ),
              Expanded(child: _Coach('Nuevo', str(to['nombre']), asNum(change['precioNuevo']))),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: <Widget>[
              _Info('Diferencia', diff > 0 ? formatCop(diff) : 'Sin costo'),
              if (diff > 0)
                _Info(
                  'Método',
                  method.isEmpty || method == 'Sin definir' ? 'Aún no elige' : method,
                ),
              if (diff > 0) _Info('Pago', statusLabel(str(payment['estado']))),
              if (str(change['motivoRechazo']).isNotEmpty)
                _Info('Motivo', str(change['motivoRechazo'])),
            ],
          ),
          if (receipt.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => showReceiptViewer(context, receipt),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.whiteA(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cyanA(0.25)),
                ),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        receipt,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.whiteA(0.06),
                          child: Icon(Icons.receipt_long_outlined, color: AppColors.whiteA(0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Factura del pago de la diferencia',
                        style: AppText.body(size: 13.5, weight: FontWeight.w600),
                      ),
                    ),
                    Text('Ver',
                        style: AppText.body(
                            size: 13, weight: FontWeight.w600, color: AppColors.cyanText)),
                  ],
                ),
              ),
            ),
          ],
          if (estado == 'pendiente_pago') ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'El usuario aún no ha registrado el pago de la diferencia.',
              style: AppText.body(size: 12.5, color: AppColors.amber, height: 1.4),
            ),
          ],
          if (pending || estado == 'pendiente_pago') ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (pending)
                  AdminButton(
                    label: diff > 0 ? 'Aprobar cambio y pago' : 'Aprobar cambio',
                    icon: Icons.check_rounded,
                    kind: AdminButtonKind.primary,
                    compact: true,
                    loading: busy,
                    onTap: onApprove,
                  ),
                AdminButton(
                  label: 'Rechazar',
                  icon: Icons.close_rounded,
                  kind: AdminButtonKind.danger,
                  compact: true,
                  onTap: busy ? null : onReject,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Coach extends StatelessWidget {
  const _Coach(this.label, this.name, this.price);

  final String label;
  final String name;
  final num price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppText.body(size: 11.5, color: AppColors.whiteA(0.40))),
          const SizedBox(height: 2),
          Text(
            name.isEmpty ? '—' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 14, weight: FontWeight.w600),
          ),
          Text(
            '${formatCop(price)}/mes',
            style: AppText.body(size: 12, color: AppColors.cyanText),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: AppText.body(size: 11.5, color: AppColors.whiteA(0.40))),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '—' : value, style: AppText.body(size: 13.5, weight: FontWeight.w600)),
      ],
    );
  }
}
