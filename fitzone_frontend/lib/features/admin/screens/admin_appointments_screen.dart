import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/appointments_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../widgets/admin_widgets.dart';

/// Citas: todas las reservas de la plataforma.
class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  String _filter = 'proximas';
  int _version = 0;
  String? _busyId;

  Future<List<Map<String, dynamic>>> _load() async {
    final String today = dateKey(DateTime.now());
    final List<Map<String, dynamic>> all = await widget.service.appointments(
      estado: _filter == 'canceladas' ? 'cancelada' : (_filter == 'proximas' ? 'confirmada' : ''),
    );
    if (_filter == 'proximas') {
      return all.where((Map<String, dynamic> a) => str(a['fecha']).compareTo(today) >= 0).toList();
    }
    return all.reversed.toList(); // más recientes primero
  }

  Future<void> _cancel(Map<String, dynamic> a) async {
    final bool ok = await adminConfirm(
      context,
      title: '¿Cancelar esta cita?',
      message:
          '${str(a['fecha'])} a las ${str(a['hora'])} con ${str(asMap(a['entrenadorId'])['nombre'])}. Se avisará al usuario.',
      confirmLabel: 'Cancelar cita',
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = str(a['_id']));
    try {
      await widget.service.cancelAppointment(str(a['_id']));
      if (!mounted) return;
      adminToast(context, 'Cita cancelada');
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
      title: 'Citas',
      subtitle: 'Reservas de los usuarios con sus entrenadores',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminChoiceChips<String>(
            options: const <(String, String)>[
              ('proximas', 'Próximas'),
              ('canceladas', 'Canceladas'),
              ('todas', 'Todas'),
            ],
            selected: _filter,
            onChanged: (String v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 18),
          AdminFuture<List<Map<String, dynamic>>>(
            key: ValueKey<String>('$_filter|$_version'),
            load: _load,
            builder: (BuildContext context, List<Map<String, dynamic>> items,
                Future<void> Function() reload) {
              if (items.isEmpty) {
                return const AdminEmpty(
                  icon: Icons.event_busy_outlined,
                  title: 'No hay citas aquí',
                  message: 'Cuando alguien agende con su entrenador aparecerá en esta lista.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < items.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 10),
                    _AppointmentCard(
                      item: items[i],
                      busy: _busyId == str(items[i]['_id']),
                      onCancel: () => _cancel(items[i]),
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

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.item, required this.busy, required this.onCancel});

  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = asMap(item['usuarioId']);
    final Map<String, dynamic> coach = asMap(item['entrenadorId']);
    final String status = str(item['estado']);
    final DateTime? start = DateTime.tryParse('${str(item['fecha'])}T${str(item['hora'])}:00');
    final bool upcoming = status == 'confirmada' && start != null && start.isAfter(DateTime.now());

    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cyanA(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cyanA(0.25)),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  str(item['hora']),
                  style: AppText.display(size: 17, weight: FontWeight.w700, color: AppColors.cyanText, height: 1.2),
                ),
                Text(
                  start == null ? '' : shortDate(start).split(' ').take(2).join(' '),
                  style: AppText.body(size: 11, color: AppColors.whiteA(0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  str(user['nombre']).isEmpty ? 'Usuario eliminado' : str(user['nombre']),
                  style: AppText.body(size: 14.5, weight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  'con ${str(coach['nombre']).isEmpty ? 'un entrenador' : str(coach['nombre'])}',
                  style: AppText.body(size: 12.5, color: AppColors.whiteA(0.50)),
                ),
                const SizedBox(height: 6),
                StatusBadge(label: statusLabel(status), color: statusColor(status)),
              ],
            ),
          ),
          if (upcoming)
            AdminButton(
              label: 'Cancelar',
              kind: AdminButtonKind.danger,
              compact: true,
              loading: busy,
              onTap: onCancel,
            ),
        ],
      ),
    );
  }
}