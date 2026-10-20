import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../widgets/admin_widgets.dart';

/// Grupos: clases por nivel con su horario y entrenador.
class AdminGroupsScreen extends StatefulWidget {
  const AdminGroupsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminGroupsScreen> createState() => _AdminGroupsScreenState();
}

class _AdminGroupsScreenState extends State<AdminGroupsScreen> {
  int _version = 0;

  Future<void> _edit([Map<String, dynamic>? group]) async {
    final bool? saved = await showAdminSheet<bool>(
      context,
      (BuildContext ctx) => _GroupForm(service: widget.service, group: group),
    );
    if (saved == true && mounted) setState(() => _version++);
  }

  Future<void> _delete(Map<String, dynamic> group) async {
    final bool ok = await adminConfirm(
      context,
      title: '¿Eliminar "${str(group['nombre'])}"?',
      message: 'Sus ${asNum(group['totalMiembros']).toInt()} miembros quedarán sin grupo.',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !mounted) return;

    try {
      await widget.service.deleteGroup(str(group['_id']));
      if (!mounted) return;
      adminToast(context, 'Grupo eliminado');
      setState(() => _version++);
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Grupos',
      subtitle: 'Clases por nivel, con su horario y entrenador',
      actions: <Widget>[
        AdminButton(
          label: 'Nuevo grupo',
          icon: Icons.add_rounded,
          kind: AdminButtonKind.primary,
          onTap: () => _edit(),
        ),
      ],
      child: AdminFuture<List<Map<String, dynamic>>>(
        key: ValueKey<int>(_version),
        load: widget.service.groups,
        builder: (BuildContext context, List<Map<String, dynamic>> groups,
            Future<void> Function() reload) {
          if (groups.isEmpty) {
            return const AdminEmpty(
              icon: Icons.groups_2_outlined,
              title: 'Aún no hay grupos',
              message: 'Crea el primero con el botón "Nuevo grupo".',
            );
          }

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int columns = c.maxWidth >= 820 ? 2 : 1;
              const double gap = 14;
              final double width = (c.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  for (final Map<String, dynamic> g in groups)
                    SizedBox(
                      width: width,
                      child: _GroupCard(
                        group: g,
                        onEdit: () => _edit(g),
                        onDelete: () => _delete(g),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onEdit, required this.onDelete});

  final Map<String, dynamic> group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String level = str(group['nivel']);
    final String coach = str(asMap(group['entrenadorId'])['nombre']);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  str(group['nombre']),
                  style: AppText.display(size: 17, weight: FontWeight.w700, height: 1.4),
                ),
              ),
              if (level.isNotEmpty)
                StatusBadge(label: statusLabel(level), color: const Color(0xFFA78BFA)),
            ],
          ),
          const SizedBox(height: 10),
          _Line(Icons.schedule_rounded, str(group['horario']).isEmpty ? 'Sin horario' : str(group['horario'])),
          _Line(Icons.fitness_center_rounded, coach.isEmpty ? 'Sin entrenador asignado' : coach),
          _Line(Icons.people_alt_outlined, '${asNum(group['totalMiembros']).toInt()} miembros'),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              AdminButton(label: 'Editar', icon: Icons.edit_outlined, compact: true, onTap: onEdit),
              const SizedBox(width: 10),
              AdminButton(
                label: 'Eliminar',
                icon: Icons.delete_outline_rounded,
                kind: AdminButtonKind.danger,
                compact: true,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.whiteA(0.45)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppText.body(size: 13.5, color: AppColors.whiteA(0.70), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _GroupForm extends StatefulWidget {
  const _GroupForm({required this.service, this.group});

  final AdminService service;
  final Map<String, dynamic>? group;

  @override
  State<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<_GroupForm> {
  late final Map<String, dynamic> _g = widget.group ?? const <String, dynamic>{};
  bool get _editing => widget.group != null;

  late final TextEditingController _name = TextEditingController(text: str(_g['nombre']));
  late final TextEditingController _schedule = TextEditingController(text: str(_g['horario']));
  late String _level = str(_g['nivel']).isEmpty ? 'principiante' : str(_g['nivel']);
  late String _coachId = str(asMap(_g['entrenadorId'])['_id']);

  List<Map<String, dynamic>> _coaches = <Map<String, dynamic>>[];
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  @override
  void dispose() {
    _name.dispose();
    _schedule.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    try {
      final List<Map<String, dynamic>> list = await widget.service.coaches();
      if (mounted) setState(() => _coaches = list);
    } on ApiException {
      // Se puede guardar sin entrenador.
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Escribe el nombre del grupo');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      await widget.service.saveGroup(
        _editing ? str(_g['_id']) : null,
        <String, dynamic>{
          'nombre': _name.text.trim(),
          'nivel': _level,
          'horario': _schedule.text.trim(),
          'entrenadorId': _coachId.isEmpty ? null : _coachId,
        },
      );
      if (!mounted) return;
      adminToast(context, _editing ? 'Grupo actualizado' : 'Grupo creado');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminSheet(
      title: _editing ? 'Editar grupo' : 'Nuevo grupo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminTextField(controller: _name, label: 'Nombre *', hint: 'Ej. Fuerza matutina', maxLength: 60),
          const SizedBox(height: 14),
          Text('Nivel', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.whiteA(0.70))),
          const SizedBox(height: 8),
          AdminChoiceChips<String>(
            options: const <(String, String)>[
              ('principiante', 'Principiante'),
              ('intermedio', 'Intermedio'),
              ('avanzado', 'Avanzado'),
            ],
            selected: _level,
            onChanged: (String v) => setState(() => _level = v),
          ),
          const SizedBox(height: 14),
          AdminTextField(
            controller: _schedule,
            label: 'Horario',
            hint: 'Ej. Lun-Mié-Vie 6:00 PM',
            maxLength: 80,
          ),
          const SizedBox(height: 14),
          Text('Entrenador', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.whiteA(0.70))),
          const SizedBox(height: 8),
          AdminChoiceChips<String>(
            options: <(String, String)>[
              ('', 'Sin entrenador'),
              for (final Map<String, dynamic> c in _coaches) (str(c['_id']), str(c['nombre'])),
            ],
            selected: _coachId,
            onChanged: (String v) => setState(() => _coachId = v),
          ),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(_error, style: AppText.body(size: 13, color: const Color(0xFFF87171))),
          ],
          const SizedBox(height: 20),
          AdminButton(
            label: _editing ? 'Guardar cambios' : 'Crear grupo',
            kind: AdminButtonKind.primary,
            loading: _saving,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}