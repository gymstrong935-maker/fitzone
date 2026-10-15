import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../admin_controller.dart';
import '../widgets/admin_widgets.dart';

/// Pagos y suscripciones: aprobar o rechazar las solicitudes.
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key, required this.service, required this.controller});

  final AdminService service;
  final AdminController controller;

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String _estado = 'pendiente';
  int _version = 0;
  String? _busyId;

  Future<void> _decide(Map<String, dynamic> sub, {required bool approve}) async {
    final String user = str(asMap(sub['usuarioId'])['nombre']);
    final String plan = str(asMap(sub['planId'])['nombre']);
    final String id = str(sub['_id']);

    final bool ok = await adminConfirm(
      context,
      title: approve ? '¿Aprobar este pago?' : '¿Rechazar este pago?',
      message: approve
          ? 'El plan "$plan" de $user quedará activo y se le notificará.'
          : 'Se rechazará la solicitud de "$plan" de $user y se le notificará.',
      confirmLabel: approve ? 'Aprobar' : 'Rechazar',
      danger: !approve,
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = id);
    try {
      if (approve) {
        await widget.service.approve(id);
      } else {
        await widget.service.reject(id);
      }
      if (!mounted) return;
      adminToast(context, approve ? 'Pago aprobado: el plan quedó activo' : 'Pago rechazado');
      widget.controller.refresh(silent: true);
      setState(() => _version++);
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Pagos y suscripciones',
      subtitle: 'Revisa las solicitudes y activa los planes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminChoiceChips<String>(
            options: const <(String, String)>[
              ('pendiente', 'Pendientes'),
              ('activa', 'Activas'),
              ('rechazada', 'Rechazadas'),
              ('', 'Todas'),
            ],
            selected: _estado,
            onChanged: (String v) => setState(() => _estado = v),
          ),
          const SizedBox(height: 18),
          AdminFuture<List<Map<String, dynamic>>>(
            key: ValueKey<String>('$_estado|$_version'),
            load: () => widget.service.subscriptions(estado: _estado),
            builder: (BuildContext context, List<Map<String, dynamic>> subs,
                Future<void> Function() reload) {
              if (subs.isEmpty) {
                return AdminEmpty(
                  icon: Icons.inbox_outlined,
                  title: _estado == 'pendiente'
                      ? 'No hay pagos pendientes'
                      : 'No hay suscripciones aquí',
                  message: 'Cuando alguien solicite un plan de pago aparecerá en esta lista.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < subs.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 12),
                    _SubscriptionCard(
                      sub: subs[i],
                      busy: _busyId == str(subs[i]['_id']),
                      onApprove: () => _decide(subs[i], approve: true),
                      onReject: () => _decide(subs[i], approve: false),
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

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.sub,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> sub;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = asMap(sub['usuarioId']);
    final Map<String, dynamic> plan = asMap(sub['planId']);
    final Map<String, dynamic> payment = asMap(sub['pago']);
    final String estado = str(sub['estado']);
    final bool pending = estado == 'pendiente';
    final DateTime? end = asDate(sub['fechaFin']);

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
                      style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.4),
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
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: <Widget>[
              _Info('Plan', str(plan['nombre'])),
              _Info('Monto', plan['precio'] == null ? '—' : formatCop(asNum(plan['precio']))),
              _Info('Método', str(payment['metodoPago']).isEmpty ? '—' : str(payment['metodoPago'])),
              _Info('Solicitud', shortDate(asDate(payment['fechaPago']))),
              if (!pending) _Info('Vence', shortDate(end)),
            ],
          ),
          if (pending) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                AdminButton(
                  label: 'Aprobar pago',
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
        Text(
          value.isEmpty ? '—' : value,
          style: AppText.body(size: 13.5, weight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }
}