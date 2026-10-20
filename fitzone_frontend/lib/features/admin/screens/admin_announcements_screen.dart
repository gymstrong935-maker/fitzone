import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../widgets/admin_widgets.dart';

/// Anuncios: notificaciones a todos, a quienes tienen plan activo o a una persona.
class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final TextEditingController _message = TextEditingController();
  final TextEditingController _email = TextEditingController();

  String _target = 'todos';
  String _type = 'sistema';
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  String get _targetLabel {
    switch (_target) {
      case 'activos':
        return 'todos los usuarios con plan activo';
      case 'usuario':
        return _email.text.trim().isEmpty ? 'un usuario' : _email.text.trim();
      default:
        return 'todos los usuarios';
    }
  }

  IconData get _typeIcon {
    switch (_type) {
      case 'recordatorio':
        return Icons.alarm_rounded;
      case 'entrenamiento':
        return Icons.fitness_center_rounded;
      case 'pago':
        return Icons.payments_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  Future<void> _send() async {
    final String text = _message.text.trim();
    if (text.length < 3) {
      adminToast(context, 'Escribe un mensaje de al menos 3 caracteres', error: true);
      return;
    }
    if (_target == 'usuario' && _email.text.trim().isEmpty) {
      adminToast(context, 'Escribe el correo del usuario', error: true);
      return;
    }

    final bool ok = await adminConfirm(
      context,
      title: '¿Enviar este anuncio?',
      message: 'Llegará como notificación a $_targetLabel.',
      confirmLabel: 'Enviar',
      danger: false,
    );
    if (!ok || !mounted) return;

    setState(() => _sending = true);
    try {
      final int sent = await widget.service.broadcast(<String, dynamic>{
        'destino': _target,
        if (_target == 'usuario') 'email': _email.text.trim(),
        'tipo': _type,
        'mensaje': text,
      });
      if (!mounted) return;
      _message.clear();
      adminToast(context, 'Anuncio enviado a $sent ${sent == 1 ? 'usuario' : 'usuarios'}');
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Anuncios',
      subtitle: 'Envía notificaciones a tus usuarios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Destinatarios', style: AppText.display(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                AdminChoiceChips<String>(
                  options: const <(String, String)>[
                    ('todos', 'Todos'),
                    ('activos', 'Con plan activo'),
                    ('usuario', 'Un usuario'),
                  ],
                  selected: _target,
                  onChanged: (String v) => setState(() => _target = v),
                ),
                if (_target == 'usuario') ...<Widget>[
                  const SizedBox(height: 12),
                  AdminTextField(
                    controller: _email,
                    hint: 'correo@del-usuario.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 18),
                Text('Tipo', style: AppText.display(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                AdminChoiceChips<String>(
                  options: const <(String, String)>[
                    ('sistema', 'Aviso'),
                    ('recordatorio', 'Recordatorio'),
                    ('entrenamiento', 'Entrenamiento'),
                    ('pago', 'Pago'),
                  ],
                  selected: _type,
                  onChanged: (String v) => setState(() => _type = v),
                ),
                const SizedBox(height: 18),
                AdminTextField(
                  controller: _message,
                  label: 'Mensaje (máx. 300)',
                  hint: 'Ej. Mañana el gimnasio abre a las 8:00 a. m.',
                  maxLines: 4,
                  maxLength: 300,
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${_message.text.length}/300',
                      style: AppText.body(size: 11.5, color: AppColors.whiteA(0.40)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Así lo verá el usuario', style: AppText.display(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cyanA(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cyanA(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.cyanA(0.14)),
                  child: Icon(_typeIcon, size: 20, color: AppColors.cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _message.text.trim().isEmpty ? 'Tu mensaje aparecerá aquí…' : _message.text.trim(),
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: _message.text.trim().isEmpty ? AppColors.whiteA(0.40) : Colors.white,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: AdminButton(
              label: 'Enviar anuncio',
              icon: Icons.send_rounded,
              kind: AdminButtonKind.primary,
              loading: _sending,
              onTap: _send,
            ),
          ),
        ],
      ),
    );
  }
}