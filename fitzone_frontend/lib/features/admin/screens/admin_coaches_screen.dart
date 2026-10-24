import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../../onboarding/widgets/fz_select.dart';
import '../widgets/admin_widgets.dart';

const List<String> _days = <String>[
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

List<String> _lines(String text) => text
    .split(RegExp(r'[\n,]'))
    .map((String e) => e.trim())
    .where((String e) => e.isNotEmpty)
    .toList();

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Entrenadores: crear, editar y eliminar.
class AdminCoachesScreen extends StatefulWidget {
  const AdminCoachesScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminCoachesScreen> createState() => _AdminCoachesScreenState();
}

class _AdminCoachesScreenState extends State<AdminCoachesScreen> {
  int _version = 0;

  Future<void> _edit([Map<String, dynamic>? coach]) async {
    final bool? saved = await showAdminSheet<bool>(
      context,
      (BuildContext ctx) => _CoachForm(service: widget.service, coach: coach),
    );
    if (saved == true && mounted) setState(() => _version++);
  }

  Future<void> _delete(Map<String, dynamic> coach) async {
    final bool ok = await adminConfirm(
      context,
      title: '¿Eliminar a ${str(coach['nombre'])}?',
      message:
          'Sus clientes quedarán sin entrenador y se cancelarán sus citas futuras. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !mounted) return;

    try {
      await widget.service.deleteCoach(str(coach['_id']));
      if (!mounted) return;
      adminToast(context, 'Entrenador eliminado');
      setState(() => _version++);
    } on ApiException catch (e) {
      if (mounted) adminToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Entrenadores',
      subtitle: 'Perfiles, precios y horarios de atención',
      actions: <Widget>[
        AdminButton(
          label: 'Nuevo entrenador',
          icon: Icons.add_rounded,
          kind: AdminButtonKind.primary,
          onTap: () => _edit(),
        ),
      ],
      child: AdminFuture<List<Map<String, dynamic>>>(
        key: ValueKey<int>(_version),
        load: widget.service.coaches,
        builder: (BuildContext context, List<Map<String, dynamic>> coaches,
            Future<void> Function() reload) {
          if (coaches.isEmpty) {
            return const AdminEmpty(
              icon: Icons.fitness_center_rounded,
              title: 'Aún no hay entrenadores',
              message: 'Crea el primero con el botón "Nuevo entrenador".',
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
                  for (final Map<String, dynamic> coach in coaches)
                    SizedBox(
                      width: width,
                      child: _CoachCard(
                        coach: coach,
                        onEdit: () => _edit(coach),
                        onDelete: () => _delete(coach),
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

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach, required this.onEdit, required this.onDelete});

  final Map<String, dynamic> coach;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String photo = str(coach['fotoPerfil']);
    final List<String> specialties = asStrings(coach['especialidad']);
    final int slots = asStrings(coach['disponibilidad']).length;
    final num rating = asNum(coach['calificacionPromedio']);

    final Widget fallback = ColoredBox(
      color: AppColors.whiteA(0.08),
      child: Icon(Icons.person_outline_rounded, size: 30, color: AppColors.whiteA(0.4)),
    );

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: photo.isEmpty
                      ? fallback
                      : Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext c, Object e, StackTrace? s) => fallback,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      str(coach['nombre']),
                      style: AppText.display(size: 16, weight: FontWeight.w700, height: 1.4),
                    ),
                    Text(
                      specialties.isEmpty ? 'Sin especialidad' : specialties.join(' · '),
                      style: AppText.body(size: 12.5, color: AppColors.cyanLightText),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        StatusBadge(
                          label: statusLabel(str(coach['nivel']).isEmpty ? 'standard' : str(coach['nivel'])),
                          color: AppColors.violet,
                        ),
                        StatusBadge(
                          label: formatCop(asNum(coach['precio'])) + str(coach['descripcionPrecio']),
                          color: AppColors.teal400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '⭐ ${rating.toStringAsFixed(1)} · ${asNum(coach['experiencia']).toInt()} años de experiencia · '
            '$slots ${slots == 1 ? 'horario' : 'horarios'} de atención',
            style: AppText.body(size: 12.5, color: AppColors.whiteA(0.55), height: 1.5),
          ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Formulario
// ═══════════════════════════════════════════════════════════════════════════

class _Slot {
  _Slot({required this.day, required this.start, required this.end});

  String day;
  TimeOfDay start;
  TimeOfDay end;

  String get text => '$day ${_hhmm(start)}-${_hhmm(end)}';

  bool get valid =>
      end.hour * 60 + end.minute >= start.hour * 60 + start.minute + 60;

  static _Slot? parse(String raw) {
    final RegExpMatch? m = RegExp(r'^\s*([^\s\d]+)\s+(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$')
        .firstMatch(raw.toLowerCase());
    if (m == null) return null;
    final String day = m.group(1)!;
    return _Slot(
      day: _days.contains(day) ? day : (day == 'miercoles' ? 'miércoles' : (day == 'sabado' ? 'sábado' : 'lunes')),
      start: TimeOfDay(hour: int.parse(m.group(2)!), minute: int.parse(m.group(3)!)),
      end: TimeOfDay(hour: int.parse(m.group(4)!), minute: int.parse(m.group(5)!)),
    );
  }
}

class _CoachForm extends StatefulWidget {
  const _CoachForm({required this.service, this.coach});

  final AdminService service;
  final Map<String, dynamic>? coach;

  @override
  State<_CoachForm> createState() => _CoachFormState();
}

class _CoachFormState extends State<_CoachForm> {
  late final Map<String, dynamic> _c = widget.coach ?? const <String, dynamic>{};
  bool get _editing => widget.coach != null;

  late final TextEditingController _name = TextEditingController(text: str(_c['nombre']));
  late final TextEditingController _specialties =
      TextEditingController(text: asStrings(_c['especialidad']).join(', '));
  late final TextEditingController _experience = TextEditingController(
    text: _c['experiencia'] == null ? '' : '${asNum(_c['experiencia']).toInt()}',
  );
  late final TextEditingController _certs =
      TextEditingController(text: asStrings(_c['certificaciones']).join(', '));
  late final TextEditingController _description = TextEditingController(text: str(_c['descripcion']));
  late final TextEditingController _type = TextEditingController(text: str(_c['tipoEntrenamiento']));
  late final TextEditingController _price = TextEditingController(
    text: _c['precio'] == null ? '' : '${asNum(_c['precio']).toInt()}',
  );
  late final TextEditingController _rating = TextEditingController(
    text: _c['calificacionPromedio'] == null ? '' : '${asNum(_c['calificacionPromedio'])}',
  );
  late final TextEditingController _services =
      TextEditingController(text: asStrings(_c['servicios']).join('\n'));
  late final TextEditingController _photo = TextEditingController(text: str(_c['fotoPerfil']));

  late String _level = str(_c['nivel']).isEmpty ? 'standard' : str(_c['nivel']);
  late final List<_Slot> _slots = <_Slot>[
    for (final String raw in asStrings(_c['disponibilidad']))
      if (_Slot.parse(raw) != null) _Slot.parse(raw)!,
  ];

  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _name, _specialties, _experience, _certs, _description, _type, _price, _rating, _services, _photo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(_Slot slot, {required bool start}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: start ? slot.start : slot.end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        slot.start = picked;
      } else {
        slot.end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Escribe el nombre del entrenador');
      return;
    }
    for (final _Slot s in _slots) {
      if (!s.valid) {
        setState(() => _error =
            'Cada horario debe durar al menos 1 hora (revisa "${s.day}").');
        return;
      }
    }

    final double? rating = double.tryParse(_rating.text.trim().replaceAll(',', '.'));
    if (rating != null && (rating < 0 || rating > 5)) {
      setState(() => _error = 'La calificación debe estar entre 0 y 5');
      return;
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'nombre': _name.text.trim(),
      'especialidad': _lines(_specialties.text),
      'experiencia': int.tryParse(_experience.text.trim()) ?? 0,
      'certificaciones': _lines(_certs.text),
      'descripcion': _description.text.trim(),
      'tipoEntrenamiento': _type.text.trim(),
      'precio': int.tryParse(_price.text.trim()) ?? 0,
      'descripcionPrecio': '/mes',
      'servicios': _lines(_services.text),
      'nivel': _level,
      'disponibilidad': <String>[for (final _Slot s in _slots) s.text],
      if (rating != null) 'calificacionPromedio': rating,
      if (_photo.text.trim().isNotEmpty) 'fotoPerfil': _photo.text.trim(),
    };

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      if (_editing) {
        await widget.service.updateCoach(str(_c['_id']), body);
      } else {
        await widget.service.createCoach(body);
      }
      if (!mounted) return;
      adminToast(context, _editing ? 'Entrenador actualizado' : 'Entrenador creado');
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
      title: _editing ? 'Editar entrenador' : 'Nuevo entrenador',
      subtitle: 'Lo que ven los usuarios al elegir su entrenador',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminTextField(controller: _name, label: 'Nombre *', hint: 'Ej. Ana Martínez', maxLength: 60),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _specialties,
            label: 'Especialidades',
            hint: 'Separadas por coma: Hipertrofia, Fuerza',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: AdminTextField(
                  controller: _experience,
                  label: 'Años de experiencia',
                  digitsOnly: true,
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminTextField(
                  controller: _price,
                  label: 'Precio por mes (COP)',
                  digitsOnly: true,
                  maxLength: 8,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminTextField(
                  controller: _rating,
                  label: 'Calificación (0-5)',
                  maxLength: 3,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Nivel', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.whiteA(0.70))),
          const SizedBox(height: 8),
          AdminChoiceChips<String>(
            options: const <(String, String)>[
              ('standard', 'Standard'),
              ('premium', 'Premium'),
              ('elite', 'Elite'),
            ],
            selected: _level,
            onChanged: (String v) => setState(() => _level = v),
          ),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _certs,
            label: 'Certificaciones',
            hint: 'Separadas por coma: NSCA-CPT, ISSA',
          ),
          const SizedBox(height: 12),
          AdminTextField(controller: _description, label: 'Descripción', maxLines: 4, maxLength: 400),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _type,
            label: 'Tipo de entrenamiento',
            hint: 'Ej. Personalizado con énfasis en técnica',
            maxLength: 120,
          ),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _services,
            label: 'Servicios incluidos (uno por línea)',
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _photo,
            label: 'Foto (URL pública)',
            hint: 'https://...',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          Text(
            'Horarios de atención',
            style: AppText.display(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Las citas duran 1 hora y se generan dentro de cada rango.',
            style: AppText.body(size: 12.5, color: AppColors.whiteA(0.45)),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _slots.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            _SlotRow(
              slot: _slots[i],
              onDay: (String d) => setState(() => _slots[i].day = d),
              onStart: () => _pickTime(_slots[i], start: true),
              onEnd: () => _pickTime(_slots[i], start: false),
              onRemove: () => setState(() => _slots.removeAt(i)),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AdminButton(
              label: 'Agregar horario',
              icon: Icons.add_rounded,
              compact: true,
              onTap: () => setState(
                () => _slots.add(
                  _Slot(
                    day: 'lunes',
                    start: const TimeOfDay(hour: 8, minute: 0),
                    end: const TimeOfDay(hour: 12, minute: 0),
                  ),
                ),
              ),
            ),
          ),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(_error, style: AppText.body(size: 13, color: AppColors.red, height: 1.4)),
          ],
          const SizedBox(height: 22),
          AdminButton(
            label: _editing ? 'Guardar cambios' : 'Crear entrenador',
            kind: AdminButtonKind.primary,
            loading: _saving,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.onDay,
    required this.onStart,
    required this.onEnd,
    required this.onRemove,
  });

  final _Slot slot;
  final ValueChanged<String> onDay;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: FzSelect<String>(
            value: slot.day,
            options: <FzSelectOption<String>>[
              for (final String d in _days)
                FzSelectOption<String>(value: d, label: d[0].toUpperCase() + d.substring(1)),
            ],
            onChanged: onDay,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _TimePill(text: _hhmm(slot.start), onTap: onStart)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('–', style: AppText.body(size: 16, color: AppColors.whiteA(0.45))),
        ),
        Expanded(
          flex: 3,
          child: _TimePill(text: _hhmm(slot.end), onTap: onEnd, invalid: !slot.valid),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRemove,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(Icons.close_rounded, size: 20, color: AppColors.whiteA(0.45)),
          ),
        ),
      ],
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.text, required this.onTap, this.invalid = false});

  final String text;
  final VoidCallback onTap;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.whiteA(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: invalid ? AppColors.red : AppColors.whiteA(0.15),
            ),
          ),
          child: Text(text, style: AppText.body(size: 14.5, color: AppColors.ink)),
        ),
      ),
    );
  }
}