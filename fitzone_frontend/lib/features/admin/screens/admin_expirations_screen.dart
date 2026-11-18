import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../admin_controller.dart';
import '../widgets/admin_widgets.dart';

/// Vencimientos: quién está por vencer, quién ya venció sin renovar, y la
/// revisión que marca los vencidos y avisa a cada usuario.
class AdminExpirationsScreen extends StatefulWidget {
  const AdminExpirationsScreen({super.key, required this.service, required this.controller});

  final AdminService service;
  final AdminController controller;

  @override
  State<AdminExpirationsScreen> createState() => _AdminExpirationsScreenState();
}

class _AdminExpirationsScreenState extends State<AdminExpirationsScreen> {
  int _days = 7;
  int _version = 0;
  bool _running = false;
  String? _notifyingId;

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      final Map<String, dynamic> result = await widget.service.runExpirations();
      if (!mounted) return;
      widget.controller.refresh(silent: true);
      setState(() => _version++);
      await showAdminSheet<void>(
        context,
        (BuildContext ctx) => _ResultSheet(result: result),
      );
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _notify(Map<String, dynamic> row) async {
    final String id = str(row['suscripcionId']);
    setState(() => _notifyingId = id);
    try {
      await widget.service.notifyExpiration(id);
      if (mounted) adminToast(context, 'Aviso enviado a ${str(row['nombre'])}');
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _notifyingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Vencimientos',
      subtitle: 'Planes por vencer y vencidos sin renovar',
      actions: <Widget>[
        AdminButton(
          label: 'Revisar vencimientos',
          icon: Icons.fact_check_outlined,
          kind: AdminButtonKind.primary,
          loading: _running,
          onTap: _run,
        ),
        AdminButton(
          label: 'Actualizar',
          icon: Icons.refresh_rounded,
          onTap: () => setState(() => _version++),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminChoiceChips<int>(
            options: const <(int, String)>[
              (3, '3 días'),
              (7, '7 días'),
              (15, '15 días'),
              (30, '30 días'),
            ],
            selected: _days,
            onChanged: (int v) => setState(() => _days = v),
          ),
          const SizedBox(height: 18),
          AdminFuture<Map<String, dynamic>>(
            key: ValueKey<String>('$_days|$_version'),
            load: () => widget.service.expirations(days: _days),
            builder: (BuildContext context, Map<String, dynamic> data,
                Future<void> Function() reload) {
              final List<Map<String, dynamic>> soon = asList(data['porVencer']);
              final List<Map<String, dynamic>> expired = asList(data['vencidas']);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Heading('Por vencer en $_days días', soon.length, AppColors.amber),
                  const SizedBox(height: 10),
                  if (soon.isEmpty)
                    const AdminEmpty(
                      icon: Icons.event_available_outlined,
                      title: 'Nadie está por vencer',
                      message: 'No hay planes que terminen en este rango de días.',
                    )
                  else
                    for (final Map<String, dynamic> row in soon) ...<Widget>[
                      _Row(
                        row: row,
                        busy: _notifyingId == str(row['suscripcionId']),
                        onNotify: () => _notify(row),
                      ),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 14),
                  _Heading('Vencidos sin renovar', expired.length, AppColors.red),
                  const SizedBox(height: 10),
                  if (expired.isEmpty)
                    const AdminEmpty(
                      icon: Icons.verified_outlined,
                      title: 'Todo renovado',
                      message: 'No hay usuarios con el plan vencido sin renovar.',
                    )
                  else
                    for (final Map<String, dynamic> row in expired) ...<Widget>[
                      _Row(
                        row: row,
                        busy: _notifyingId == str(row['suscripcionId']),
                        onNotify: () => _notify(row),
                      ),
                      const SizedBox(height: 10),
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

class _Heading extends StatelessWidget {
  const _Heading(this.text, this.count, this.color);

  final String text;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(text, style: AppText.display(size: 17, height: 1.3)),
        const SizedBox(width: 10),
        StatusBadge(label: '$count', color: color),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.busy, required this.onNotify});

  final Map<String, dynamic> row;
  final bool busy;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    final int? days = row['dias'] == null ? null : asNum(row['dias']).toInt();
    final bool expired = days != null && days < 0;
    final String when = days == null
        ? '—'
        : expired
            ? 'Venció hace ${-days} ${-days == 1 ? 'día' : 'días'}'
            : days == 0
                ? 'Vence hoy'
                : days == 1
                    ? 'Vence mañana'
                    : 'Vence en $days días';

    return AdminCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  str(row['nombre']),
                  style: AppText.display(size: 15.5, height: 1.35),
                ),
                Text(
                  str(row['email']),
                  style: AppText.body(size: 12.5, color: AppColors.whiteA(0.45)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    StatusBadge(label: str(row['plan']), color: AppColors.cyan),
                    StatusBadge(
                      label: when,
                      color: expired ? AppColors.red : AppColors.amber,
                    ),
                    Text(
                      shortDate(asDate(row['fechaFin'])),
                      style: AppText.body(size: 12, color: AppColors.whiteA(0.4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AdminButton(
            label: 'Avisar',
            icon: Icons.notifications_active_outlined,
            compact: true,
            loading: busy,
            onTap: onNotify,
          ),
        ],
      ),
    );
  }
}

/// Resultado de "Revisar vencimientos".
class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> expired = asList(result['vencidasAhora']);
    final List<Map<String, dynamic>> soon = asList(result['porVencer']);
    final int sent = asNum(result['notificacionesEnviadas']).toInt();

    return AdminSheet(
      title: 'Vencimientos revisados',
      subtitle: sent == 0
          ? 'No hubo avisos nuevos (ya estaban notificados).'
          : 'Se enviaron $sent avisos (notificación y correo).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _Stat('Marcadas como vencidas', asNum(result['suscripcionesVencidas']).toInt(), AppColors.red),
              _Stat('Avisos por vencer', asNum(result['avisosPorVencer']).toInt(), AppColors.amber),
              _Stat('Avisos de vencidas', asNum(result['avisosVencidas']).toInt(), AppColors.violet),
            ],
          ),
          if (expired.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text('Acaban de vencer', style: AppText.display(size: 15)),
            const SizedBox(height: 8),
            for (final Map<String, dynamic> r in expired)
              _Line('${str(r['nombre'])} · ${str(r['plan'])}', 'venció ${shortDate(asDate(r['fechaFin']))}'),
          ],
          if (soon.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text('Próximos a vencer', style: AppText.display(size: 15)),
            const SizedBox(height: 8),
            for (final Map<String, dynamic> r in soon)
              _Line(
                '${str(r['nombre'])} · ${str(r['plan'])}',
                '${asNum(r['dias']).toInt()} d${r['avisado'] == true ? ' · avisado' : ''}',
              ),
          ],
          if (expired.isEmpty && soon.isEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              'No hay planes por vencer ni recién vencidos. Todo en orden.',
              style: AppText.body(size: 14, color: AppColors.whiteA(0.55)),
            ),
          ],
          const SizedBox(height: 18),
          AdminButton(
            label: 'Cerrar',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$value', style: AppText.display(size: 22, color: color, height: 1.1)),
          Text(label, style: AppText.body(size: 11.5, color: AppColors.whiteA(0.55))),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.left, this.right);

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(left, style: AppText.body(size: 13.5))),
          Text(right, style: AppText.body(size: 12.5, color: AppColors.whiteA(0.5))),
        ],
      ),
    );
  }
}
