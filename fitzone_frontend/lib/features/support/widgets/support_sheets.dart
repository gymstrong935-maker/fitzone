import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/app_services.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/support_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/error_box.dart';
import '../../admin/widgets/admin_widgets.dart';

/// "Hablar con una persona": crea una solicitud con la conversación adjunta.
/// Devuelve `true` si se envió.
Future<bool?> showSupportRequestSheet(
  BuildContext context, {
  required List<ChatTurn> transcript,
}) {
  return showAdminSheet<bool>(
    context,
    (BuildContext ctx) => _RequestSheet(transcript: transcript),
  );
}

/// Lista de las solicitudes del usuario, con las respuestas del equipo.
Future<void> showMyTicketsSheet(BuildContext context) {
  return showAdminSheet<void>(context, (BuildContext ctx) => const _TicketsSheet());
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.transcript});

  final List<ChatTurn> transcript;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  late final TextEditingController _subject = TextEditingController(text: _suggestSubject());
  final TextEditingController _message = TextEditingController();

  bool _sending = false;
  String _error = '';

  String _suggestSubject() {
    for (final ChatTurn t in widget.transcript) {
      if (t.role == 'user') {
        final String text = t.content.trim();
        return text.length <= 60 ? text : '${text.substring(0, 57)}...';
      }
    }
    return '';
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String subject = _subject.text.trim();
    final String message = _message.text.trim();

    if (subject.length < 3) {
      setState(() => _error = 'Escribe un asunto (mínimo 3 caracteres)');
      return;
    }
    if (message.length < 5) {
      setState(() => _error = 'Cuéntanos un poco más sobre tu problema');
      return;
    }

    setState(() {
      _sending = true;
      _error = '';
    });

    try {
      await AppServices.instance.support.create(
        subject: subject,
        message: message,
        transcript: widget.transcript,
      );
      if (!mounted) return;
      adminToast(context, 'Listo: el equipo te responderá por aquí y con una notificación');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminSheet(
      title: 'Hablar con una persona',
      subtitle: 'Cuéntanos qué pasa y el equipo de FitZone te responderá',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminTextField(
            controller: _subject,
            label: 'Asunto',
            hint: 'Ej. Mi pago no se ha aprobado',
            maxLength: 120,
          ),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _message,
            label: 'Mensaje',
            hint: 'Describe tu problema con el mayor detalle posible',
            maxLines: 5,
            maxLength: 2000,
          ),
          if (widget.transcript.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.attach_file_rounded, size: 15, color: AppColors.whiteA(0.40)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Se adjuntará tu conversación con el asistente para que el equipo tenga contexto.',
                    style: AppText.body(size: 12, color: AppColors.whiteA(0.45), height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          if (_error.isNotEmpty) ...<Widget>[const SizedBox(height: 14), ErrorBox(_error)],
          const SizedBox(height: 20),
          AdminButton(
            label: 'Enviar solicitud',
            icon: Icons.send_rounded,
            kind: AdminButtonKind.primary,
            loading: _sending,
            onTap: _send,
          ),
        ],
      ),
    );
  }
}

class _TicketsSheet extends StatelessWidget {
  const _TicketsSheet();

  @override
  Widget build(BuildContext context) {
    return AdminSheet(
      title: 'Mis solicitudes',
      subtitle: 'Tus conversaciones con el equipo de soporte',
      child: AdminFuture<List<SupportTicket>>(
        load: AppServices.instance.support.mine,
        builder: (BuildContext context, List<SupportTicket> tickets,
            Future<void> Function() reload) {
          if (tickets.isEmpty) {
            return const AdminEmpty(
              icon: Icons.forum_outlined,
              title: 'Aún no tienes solicitudes',
              message: 'Si el asistente no resuelve tu duda, usa "Hablar con una persona".',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < tickets.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 10),
                _TicketTile(ticket: tickets[i], onChanged: reload),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TicketTile extends StatefulWidget {
  const _TicketTile({required this.ticket, required this.onChanged});

  final SupportTicket ticket;
  final Future<void> Function() onChanged;

  @override
  State<_TicketTile> createState() => _TicketTileState();
}

class _TicketTileState extends State<_TicketTile> {
  final TextEditingController _reply = TextEditingController();
  bool _open = false;
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _reply.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await AppServices.instance.support.addMessage(widget.ticket.id, text);
      if (!mounted) return;
      _reply.clear();
      await widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SupportTicket t = widget.ticket;
    final Color color = statusColor(t.status);

    return AdminCard(
      padding: const EdgeInsets.all(14),
      highlight: t.hasAdminReply && !t.isClosed ? AppColors.cyanA(0.30) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        t.subject,
                        style: AppText.body(size: 14.5, weight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Actualizada ${formatRelativeTime(t.updatedAt).toLowerCase()}'
                        '${t.hasAdminReply ? ' · con respuesta del equipo' : ''}',
                        style: AppText.body(size: 12, color: AppColors.whiteA(0.45)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(label: t.statusLabel, color: color),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: AppColors.whiteA(0.45),
                ),
              ],
            ),
          ),
          if (_open) ...<Widget>[
            const SizedBox(height: 12),
            _Msg(text: t.message, fromAdmin: false, label: 'Tú'),
            for (final SupportReply r in t.replies) ...<Widget>[
              const SizedBox(height: 8),
              _Msg(
                text: r.message,
                fromAdmin: r.fromAdmin,
                label: r.fromAdmin ? 'Soporte FitZone' : 'Tú',
              ),
            ],
            const SizedBox(height: 12),
            AdminTextField(
              controller: _reply,
              hint: t.isClosed ? 'Escribe para reabrir la solicitud' : 'Escribe un mensaje',
              maxLines: 3,
              maxLength: 1000,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AdminButton(
                label: 'Enviar',
                icon: Icons.send_rounded,
                compact: true,
                loading: _sending,
                onTap: _send,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Msg extends StatelessWidget {
  const _Msg({required this.text, required this.fromAdmin, required this.label});

  final String text;
  final bool fromAdmin;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                label,
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: fromAdmin ? AppColors.cyanText : AppColors.whiteA(0.50),
                ),
              ),
              const SizedBox(height: 3),
              Text(text, style: AppText.body(size: 14, color: AppColors.ink, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}