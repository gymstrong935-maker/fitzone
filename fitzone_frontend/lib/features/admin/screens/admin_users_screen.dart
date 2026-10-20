import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../widgets/admin_widgets.dart';
import '../admin_controller.dart';

/// Usuarios: búsqueda, aprobación de cuentas nuevas, rol, estado y avisos.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.service, required this.controller});

  final AdminService service;
  final AdminController controller;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _query = '';

  /// '' = todos · 'pendiente' = por aprobar · 'cliente' / 'admin' = por rol
  String _filter = '';
  int _version = 0;
  String? _busyId;

  Future<void> _open(Map<String, dynamic> user) async {
    final bool? changed = await showAdminSheet<bool>(
      context,
      (BuildContext ctx) => _UserSheet(service: widget.service, userId: str(user['_id'])),
    );
    if (changed == true && mounted) {
      widget.controller.refresh(silent: true);
      setState(() => _version++);
    }
  }

  Future<void> _approve(Map<String, dynamic> user) async {
    final bool ok = await adminConfirm(
      context,
      title: '¿Aprobar esta cuenta?',
      message:
          '${str(user['nombre'])} podrá continuar en FitZone y recibirá una notificación y un correo.',
      confirmLabel: 'Aprobar',
      danger: false,
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = str(user['_id']));
    try {
      await widget.service.approveUser(str(user['_id']));
      if (!mounted) return;
      adminToast(context, 'Cuenta aprobada');
      widget.controller.refresh(silent: true);
      setState(() => _version++);
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(Map<String, dynamic> user) async {
    final String? reason = await showAdminSheet<String>(
      context,
      (BuildContext ctx) => _RejectSheet(name: str(user['nombre'])),
    );
    if (reason == null || !mounted) return; // cancelado

    setState(() => _busyId = str(user['_id']));
    try {
      await widget.service.rejectUser(str(user['_id']), reason: reason);
      if (!mounted) return;
      adminToast(context, 'Cuenta rechazada');
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
    final bool pendingOnly = _filter == 'pendiente';

    return AdminPage(
      title: 'Usuarios',
      subtitle: 'Todas las cuentas de FitZone',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminSearchField(
            hint: 'Buscar por nombre o correo',
            onChanged: (String v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          AdminChoiceChips<String>(
            options: const <(String, String)>[
              ('', 'Todos'),
              ('pendiente', 'Por aprobar'),
              ('cliente', 'Clientes'),
              ('admin', 'Administradores'),
            ],
            selected: _filter,
            onChanged: (String v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 18),
          AdminFuture<Map<String, dynamic>>(
            key: ValueKey<String>('$_query|$_filter|$_version'),
            load: () => widget.service.users(
              q: _query,
              rol: pendingOnly ? '' : _filter,
              estado: pendingOnly ? 'pendiente' : '',
            ),
            builder: (BuildContext context, Map<String, dynamic> data,
                Future<void> Function() reload) {
              final List<Map<String, dynamic>> users = asList(data['usuarios']);
              final int total = asNum(data['total']).toInt();

              if (users.isEmpty) {
                return AdminEmpty(
                  icon: pendingOnly ? Icons.how_to_reg_outlined : Icons.person_search_outlined,
                  title: pendingOnly ? 'No hay cuentas por aprobar' : 'No se encontraron usuarios',
                  message: pendingOnly
                      ? 'Las cuentas nuevas aparecerán aquí cuando verifiquen su correo.'
                      : 'Prueba con otra búsqueda o cambia el filtro.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    total > users.length
                        ? 'Mostrando ${users.length} de $total (afina la búsqueda para ver más)'
                        : '$total ${total == 1 ? 'usuario' : 'usuarios'}',
                    style: AppText.body(size: 12, color: AppColors.whiteA(0.40)),
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < users.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 10),
                    _UserCard(
                      user: users[i],
                      busy: _busyId == str(users[i]['_id']),
                      onTap: () => _open(users[i]),
                      onApprove: () => _approve(users[i]),
                      onReject: () => _reject(users[i]),
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

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.busy,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> user;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final String name = str(user['nombre']);
    final String rol = str(user['rol']);
    final String estado = str(user['estadoCuenta']);
    final String plan = str(asMap(user['planActual'])['nombre']);
    final bool pending = estado == 'pendiente' && rol != 'admin';
    final bool verified = user['cuentaVerificada'] != false;

    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      highlight: pending ? const Color.fromRGBO(251, 191, 36, 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: <Color>[AppColors.cyan, AppColors.teal]),
                ),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: AppText.body(size: 18, weight: FontWeight.w700, color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 14.5, weight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      str(user['email']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 12.5, color: AppColors.whiteA(0.45)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        if (rol.isNotEmpty)
                          StatusBadge(
                            label: statusLabel(rol),
                            color: rol == 'admin' ? const Color(0xFFA78BFA) : AppColors.cyan,
                          ),
                        if (estado.isNotEmpty)
                          StatusBadge(
                            label: estado == 'pendiente' ? 'Por aprobar' : statusLabel(estado),
                            color: statusColor(estado),
                          ),
                        if (plan.isNotEmpty)
                          StatusBadge(label: plan, color: const Color(0xFF2DD4BF)),
                        if (!verified)
                          const StatusBadge(label: 'Correo sin verificar', color: Color(0xFFF87171)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.whiteA(0.30)),
            ],
          ),
          if (pending) ...<Widget>[
            const SizedBox(height: 14),
            if (!verified)
              Text(
                'Todavía no verificó su correo: puedes aprobarla cuando lo haga.',
                style: AppText.body(size: 12, color: AppColors.whiteA(0.45), height: 1.4),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  AdminButton(
                    label: 'Aprobar cuenta',
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

/// Hoja para rechazar una cuenta (con motivo opcional).
class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.name});

  final String name;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminSheet(
      title: 'Rechazar cuenta',
      subtitle: widget.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminTextField(
            controller: _reason,
            label: 'Motivo (opcional, lo verá el usuario)',
            hint: 'Ej. No pudimos validar tus datos',
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: AdminButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: AdminButton(
                    label: 'Rechazar cuenta',
                    kind: AdminButtonKind.danger,
                    onTap: () => Navigator.of(context).pop(_reason.text.trim()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Detalle de un usuario
// ═══════════════════════════════════════════════════════════════════════════

class _UserSheet extends StatelessWidget {
  const _UserSheet({required this.service, required this.userId});

  final AdminService service;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return AdminSheet(
      title: 'Usuario',
      child: AdminFuture<Map<String, dynamic>>(
        load: () => service.userDetail(userId),
        builder: (BuildContext context, Map<String, dynamic> data,
            Future<void> Function() reload) {
          return _UserEditor(service: service, data: data);
        },
      ),
    );
  }
}

class _UserEditor extends StatefulWidget {
  const _UserEditor({required this.service, required this.data});

  final AdminService service;
  final Map<String, dynamic> data;

  @override
  State<_UserEditor> createState() => _UserEditorState();
}

class _UserEditorState extends State<_UserEditor> {
  late final Map<String, dynamic> _user = asMap(widget.data['usuario']);
  late final TextEditingController _name = TextEditingController(text: str(_user['nombre']));
  late final TextEditingController _phone = TextEditingController(text: str(_user['telefono']));
  final TextEditingController _notice = TextEditingController();

  late String _rol = str(_user['rol']);
  late String _estado = str(_user['estadoCuenta']);
  bool _saving = false;
  bool _changed = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notice.dispose();
    super.dispose();
  }

  List<String> _options(String key) => asStrings(asMap(widget.data['opciones'])[key]);

  Future<void> _save() async {
    final Map<String, dynamic> body = <String, dynamic>{
      if (_name.text.trim() != str(_user['nombre'])) 'nombre': _name.text.trim(),
      if (_phone.text.trim() != str(_user['telefono'])) 'telefono': _phone.text.trim(),
      if (_rol != str(_user['rol'])) 'rol': _rol,
      if (_estado != str(_user['estadoCuenta'])) 'estadoCuenta': _estado,
    };
    if (body.isEmpty) {
      Navigator.of(context).pop(_changed);
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await widget.service.updateUser(str(_user['_id']), body);
      if (!mounted) return;
      adminToast(context, 'Usuario actualizado');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  Future<void> _sendNotice() async {
    final String message = _notice.text.trim();
    if (message.length < 3) {
      adminToast(context, 'Escribe un mensaje de al menos 3 caracteres', error: true);
      return;
    }
    try {
      await widget.service.broadcast(<String, dynamic>{
        'destino': 'usuario',
        'email': str(_user['email']),
        'tipo': 'sistema',
        'mensaje': message,
      });
      if (!mounted) return;
      _notice.clear();
      adminToast(context, 'Notificación enviada');
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    }
  }

  Future<void> _revoke() async {
    final String? reason = await showAdminSheet<String>(
      context,
      (BuildContext ctx) => _RevokeSheet(
        name: str(_user['nombre']),
        email: str(_user['email']),
      ),
    );
    if (reason == null || !mounted) return;

    try {
      await widget.service.revokeUser(str(_user['_id']), reason: reason);
      if (!mounted) return;
      adminToast(context, 'Cuenta eliminada. Si intenta entrar verá que fue revocada.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> subs = asList(widget.data['suscripciones']);
    final List<Map<String, dynamic>> payments = asList(widget.data['pagos']);
    final List<String> roles = _options('roles');
    final List<String> states = _options('estados');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          str(_user['email']),
          style: AppText.body(size: 14, color: AppColors.whiteA(0.55)),
        ),
        const SizedBox(height: 4),
        Text(
          'Registro: ${shortDate(asDate(_user['fechaRegistro']))} · '
          '${asNum(widget.data['entrenamientos']).toInt()} entrenamientos · '
          'Plan: ${str(asMap(_user['planActual'])['nombre']).isEmpty ? '—' : str(asMap(_user['planActual'])['nombre'])}'
          '${str(asMap(_user['entrenadorAsignado'])['nombre']).isEmpty ? '' : ' · Entrenador: ${str(asMap(_user['entrenadorAsignado'])['nombre'])}'}',
          style: AppText.body(size: 12.5, color: AppColors.whiteA(0.40), height: 1.5),
        ),
        const SizedBox(height: 18),
        AdminTextField(controller: _name, label: 'Nombre', maxLength: 60),
        const SizedBox(height: 12),
        AdminTextField(
          controller: _phone,
          label: 'Teléfono',
          keyboardType: TextInputType.phone,
          maxLength: 30,
        ),
        if (roles.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text('Rol', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.whiteA(0.70))),
          const SizedBox(height: 8),
          AdminChoiceChips<String>(
            options: <(String, String)>[for (final String r in roles) (r, statusLabel(r))],
            selected: _rol,
            onChanged: (String v) => setState(() => _rol = v),
          ),
        ],
        if (states.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text('Estado de la cuenta', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.whiteA(0.70))),
          const SizedBox(height: 8),
          AdminChoiceChips<String>(
            options: <(String, String)>[for (final String s in states) (s, statusLabel(s))],
            selected: _estado,
            onChanged: (String v) => setState(() => _estado = v),
          ),
        ],
        if (_error.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(_error, style: AppText.body(size: 13, color: const Color(0xFFF87171))),
        ],
        const SizedBox(height: 18),
        AdminButton(
          label: 'Guardar cambios',
          kind: AdminButtonKind.primary,
          loading: _saving,
          onTap: _save,
        ),
        const SizedBox(height: 28),
        Text('Enviar una notificación', style: AppText.display(size: 15, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        AdminTextField(controller: _notice, hint: 'Mensaje para este usuario', maxLength: 300),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: AdminButton(label: 'Enviar', icon: Icons.send_rounded, compact: true, onTap: _sendNotice),
        ),
        const SizedBox(height: 28),
        Text('Suscripciones', style: AppText.display(size: 15, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (subs.isEmpty)
          Text('Sin suscripciones.', style: AppText.body(size: 13, color: AppColors.whiteA(0.45)))
        else
          for (final Map<String, dynamic> s in subs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${str(asMap(s['planId'])['nombre'])} · vence ${shortDate(asDate(s['fechaFin']))}',
                      style: AppText.body(size: 13, color: AppColors.whiteA(0.75)),
                    ),
                  ),
                  StatusBadge(label: statusLabel(str(s['estado'])), color: statusColor(str(s['estado']))),
                ],
              ),
            ),
        const SizedBox(height: 18),
        Text('Pagos', style: AppText.display(size: 15, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (payments.isEmpty)
          Text('Sin pagos.', style: AppText.body(size: 13, color: AppColors.whiteA(0.45)))
        else
          for (final Map<String, dynamic> p in payments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${formatCop(asNum(p['monto']))} · ${str(p['metodoPago'])} · ${shortDate(asDate(p['fechaPago']))}',
                      style: AppText.body(size: 13, color: AppColors.whiteA(0.75)),
                    ),
                  ),
                  StatusBadge(label: statusLabel(str(p['estado'])), color: statusColor(str(p['estado']))),
                ],
              ),
            ),
        if (str(_user['rol']) != 'admin') ...<Widget>[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(239, 68, 68, 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color.fromRGBO(239, 68, 68, 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Zona de peligro',
                  style: AppText.display(size: 15, weight: FontWeight.w700, color: const Color(0xFFF87171)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Eliminar la cuenta revoca el acceso de este usuario.',
                  style: AppText.body(size: 13, color: AppColors.whiteA(0.55), height: 1.5),
                ),
                const SizedBox(height: 12),
                AdminButton(
                  label: 'Eliminar cuenta',
                  icon: Icons.delete_forever_outlined,
                  kind: AdminButtonKind.danger,
                  compact: true,
                  onTap: _revoke,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Confirmación para eliminar una cuenta: hay que escribir el correo.
class _RevokeSheet extends StatefulWidget {
  const _RevokeSheet({required this.name, required this.email});

  final String name;
  final String email;

  @override
  State<_RevokeSheet> createState() => _RevokeSheetState();
}

class _RevokeSheetState extends State<_RevokeSheet> {
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  bool get _matches =>
      _confirm.text.trim().toLowerCase() == widget.email.trim().toLowerCase();

  @override
  void dispose() {
    _confirm.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminSheet(
      title: 'Eliminar cuenta',
      subtitle: widget.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Se borrarán sus datos (entrenamientos, comidas, medidas, notificaciones y solicitudes), '
            'se cancelarán sus citas y suscripciones, y la cuenta quedará revocada: '
            'si intenta entrar verá un aviso. Los pagos se conservan. Esta acción no se puede deshacer.',
            style: AppText.body(size: 13.5, color: AppColors.whiteA(0.60), height: 1.55),
          ),
          const SizedBox(height: 16),
          AdminTextField(
            controller: _reason,
            label: 'Motivo (opcional, lo verá el usuario)',
            maxLength: 200,
          ),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _confirm,
            label: 'Escribe ${widget.email} para confirmar',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: AdminButton(label: 'Cancelar', onTap: () => Navigator.of(context).pop()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: AdminButton(
                    label: 'Eliminar cuenta',
                    kind: AdminButtonKind.danger,
                    onTap: _matches ? () => Navigator.of(context).pop(_reason.text.trim()) : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}