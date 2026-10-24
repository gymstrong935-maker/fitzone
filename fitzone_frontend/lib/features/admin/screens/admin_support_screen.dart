import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../admin_controller.dart';
import '../widgets/admin_widgets.dart';

/// Soporte: solicitudes de los usuarios (las que no resolvió el chatbot).
class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key, required this.service, required this.controller});

  final AdminService service;
  final AdminController controller;

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  String _estado = 'abierto';
  int _version = 0;

  Future<void> _open(Map<String, dynamic> ticket) async {
    await showAdminSheet<void>(
      context,
      (BuildContext ctx) => _TicketSheet(service: widget.service, ticketId: str(ticket['_id'])),
    );
    widget.controller.refresh(silent: true);
    if (mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Soporte',
      subtitle: 'Solicitudes de ayuda de los usuarios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminChoiceChips<String>(
            options: const <(String, String)>[
              ('abierto', 'Abiertas'),
              ('en_proceso', 'En proceso'),
              ('cerrado', 'Cerradas'),
              ('', 'Todas'),
            ],
            selected: _estado,
            onChanged: (String v) => setState(() => _estado = v),
          ),
          const SizedBox(height: 18),
          AdminFuture<List<Map<String, dynamic>>>(
            key: ValueKey<String>('$_estado|$_version'),
            load: () => widget.service.tickets(estado: _estado),
            builder: (BuildContext context, List<Map<String, dynamic>> tickets,
                Future<void> Function() reload) {
              if (tickets.isEmpty) {
                return const AdminEmpty(
                  icon: Icons.mark_email_read_outlined,
                  title: 'No hay solicitudes aquí',
                  message: 'Cuando un usuario pida hablar con una persona aparecerá en esta lista.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < tickets.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 10),
                    _TicketCard(ticket: tickets[i], onTap: () => _open(tickets[i])),
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final Map<String, dynamic> ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = asMap(ticket['usuarioId']);
    final String estado = str(ticket['estado']);
    final List<Map<String, dynamic>> replies = asList(ticket['respuestas']);
    final bool waitingForAdmin = replies.isEmpty || str(replies.last['autor']) == 'usuario';

    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      highlight: estado != 'cerrado' && waitingForAdmin
          ? const Color.fromRGBO(251, 191, 36, 0.30)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  str(ticket['asunto']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 15, weight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: statusLabel(estado), color: statusColor(estado)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${str(user['nombre'])} · ${str(user['email'])}',
            style: AppText.body(size: 12.5, color: AppColors.whiteA(0.45)),
          ),
          const SizedBox(height: 8),
          Text(
            str(ticket['mensaje']),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 13, color: AppColors.whiteA(0.65), height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatRelativeTime(asDate(ticket['updatedAt']) ?? DateTime.now())} · ${replies.length} ${replies.length == 1 ? 'respuesta' : 'respuestas'}'
            '${estado != 'cerrado' && waitingForAdmin ? ' · espera tu respuesta' : ''}',
            style: AppText.body(size: 12, color: AppColors.whiteA(0.40)),
          ),
        ],
      ),
    );
  }
}

class _TicketSheet extends StatelessWidget {
  const _TicketSheet({required this.service, required this.ticketId});

  final AdminService service;
  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return AdminSheet(
      title: 'Solicitud de soporte',
      child: AdminFuture<Map<String, dynamic>>(
        load: () => service.ticket(ticketId),
        builder: (BuildContext context, Map<String, dynamic> ticket,
            Future<void> Function() reload) {
          return _TicketDetail(service: service, initial: ticket);
        },
      ),
    );
  }
}

class _TicketDetail extends StatefulWidget {
  const _TicketDetail({required this.service, required this.initial});

  final AdminService service;
  final Map<String, dynamic> initial;

  @override
  State<_TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends State<_TicketDetail> {
  late Map<String, dynamic> _ticket = widget.initial;
  final TextEditingController _reply = TextEditingController();
  bool _sending = false;
  bool _showChat = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send({String? estado}) async {
    final String message = _reply.text.trim();
    if (message.isEmpty) {
      adminToast(context, 'Escribe una respuesta', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final Map<String, dynamic> updated = await widget.service.replyTicket(
        str(_ticket['_id']),
        message,
        estado: estado,
      );
      if (!mounted) return;
      _reply.clear();
      setState(() => _ticket = updated);
      adminToast(context, 'Respuesta enviada: el usuario recibió una notificación');
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setState(String estado) async {
    try {
      await widget.service.setTicketState(str(_ticket['_id']), estado);
      if (!mounted) return;
      setState(() => _ticket = <String, dynamic>{..._ticket, 'estado': estado});
      adminToast(context, estado == 'cerrado' ? 'Solicitud cerrada' : 'Solicitud reabierta');
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = asMap(_ticket['usuarioId']);
    final String estado = str(_ticket['estado']);
    final List<Map<String, dynamic>> replies = asList(_ticket['respuestas']);
    final List<Map<String, dynamic>> transcript = asList(_ticket['transcripcion']);
    final bool closed = estado == 'cerrado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                str(_ticket['asunto']),
                style: AppText.display(size: 17, weight: FontWeight.w700, height: 1.4),
              ),
            ),
            StatusBadge(label: statusLabel(estado), color: statusColor(estado)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${str(user['nombre'])} · ${str(user['email'])} · ${shortDateTime(asDate(_ticket['createdAt']))}',
          style: AppText.body(size: 12.5, color: AppColors.whiteA(0.45), height: 1.5),
        ),
        const SizedBox(height: 14),
        _Bubble(text: str(_ticket['mensaje']), fromAdmin: false, label: 'Usuario'),
        for (final Map<String, dynamic> r in replies) ...<Widget>[
          const SizedBox(height: 10),
          _Bubble(
            text: str(r['mensaje']),
            fromAdmin: str(r['autor']) == 'admin',
            label: str(r['autor']) == 'admin' ? 'Soporte' : 'Usuario',
            date: asDate(r['fecha']),
          ),
        ],
        if (transcript.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showChat = !_showChat),
            child: Row(
              children: <Widget>[
                Icon(
                  _showChat ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.cyanText,
                ),
                const SizedBox(width: 6),
                Text(
                  _showChat ? 'Ocultar conversación con el chatbot' : 'Ver conversación con el chatbot (${transcript.length})',
                  style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.cyanText),
                ),
              ],
            ),
          ),
          if (_showChat)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.whiteA(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.whiteA(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final Map<String, dynamic> t in transcript)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text.rich(
                        TextSpan(
                          style: AppText.body(size: 12.5, color: AppColors.whiteA(0.70), height: 1.5),
                          children: <TextSpan>[
                            TextSpan(
                              text: str(t['rol']) == 'user' ? 'Usuario: ' : 'Chatbot: ',
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: str(t['rol']) == 'user' ? AppColors.ink : AppColors.cyanText,
                              ),
                            ),
                            TextSpan(text: str(t['contenido'])),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 20),
        AdminTextField(
          controller: _reply,
          label: closed ? 'Responder (reabre la solicitud)' : 'Tu respuesta',
          hint: 'Escribe una respuesta clara para el usuario',
          maxLines: 4,
          maxLength: 1000,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            AdminButton(
              label: 'Responder',
              icon: Icons.send_rounded,
              kind: AdminButtonKind.primary,
              loading: _sending,
              onTap: () => _send(estado: closed ? 'abierto' : null),
            ),
            AdminButton(
              label: 'Responder y cerrar',
              icon: Icons.done_all_rounded,
              onTap: _sending || closed ? null : () => _send(estado: 'cerrado'),
            ),
            if (closed)
              AdminButton(label: 'Reabrir', icon: Icons.restart_alt_rounded, onTap: () => _setState('abierto'))
            else
              AdminButton(label: 'Marcar como cerrada', onTap: () => _setState('cerrado')),
          ],
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromAdmin, required this.label, this.date});

  final String text;
  final bool fromAdmin;
  final String label;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fromAdmin ? AppColors.cyanA(0.12) : AppColors.whiteA(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fromAdmin ? AppColors.cyanA(0.30) : AppColors.whiteA(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                date == null ? label : '$label · ${shortDateTime(date)}',
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: fromAdmin ? AppColors.cyanText : AppColors.whiteA(0.50),
                ),
              ),
              const SizedBox(height: 4),
              Text(text, style: AppText.body(size: 14, color: AppColors.ink, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}