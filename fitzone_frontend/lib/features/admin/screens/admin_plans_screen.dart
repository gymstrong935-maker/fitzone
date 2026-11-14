import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../widgets/admin_widgets.dart';

/// Planes: editar nombre, precio, duración y beneficios.
class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  int _version = 0;

  Future<void> _edit(Map<String, dynamic> plan) async {
    final bool? saved = await showAdminSheet<bool>(
      context,
      (BuildContext ctx) => _PlanForm(service: widget.service, plan: plan),
    );
    if (saved == true && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Planes',
      subtitle: 'Los cambios se reflejan al instante en la app de los usuarios',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Conserva las palabras "Mensual" y "Anual" en el nombre de esos planes: '
                    'la app las usa para reconocerlos.',
                    style: AppText.body(size: 12.5, color: AppColors.whiteA(0.60), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminFuture<List<Map<String, dynamic>>>(
            key: ValueKey<int>(_version),
            load: widget.service.plans,
            builder: (BuildContext context, List<Map<String, dynamic>> plans,
                Future<void> Function() reload) {
              if (plans.isEmpty) {
                return const AdminEmpty(
                  icon: Icons.sell_outlined,
                  title: 'No hay planes',
                  message: 'Ejecuta "npm run seed" en el backend para crear los planes base.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < plans.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 12),
                    _PlanCard(plan: plans[i], onEdit: () => _edit(plans[i])),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onEdit});

  final Map<String, dynamic> plan;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bool free = plan['esGratuito'] == true;
    final List<String> benefits = asStrings(plan['beneficios']);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  str(plan['nombre']),
                  style: AppText.display(size: 18, weight: FontWeight.w700, height: 1.4),
                ),
              ),
              if (free) StatusBadge(label: 'Gratuito', color: AppColors.green),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${free ? 'Gratis' : formatCop(asNum(plan['precio']))} · ${asNum(plan['duracionDias']).toInt()} días',
            style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.cyanLightText),
          ),
          const SizedBox(height: 10),
          for (final String b in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $b', style: AppText.body(size: 13, color: AppColors.whiteA(0.65), height: 1.45)),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AdminButton(label: 'Editar plan', icon: Icons.edit_outlined, compact: true, onTap: onEdit),
          ),
        ],
      ),
    );
  }
}

class _PlanForm extends StatefulWidget {
  const _PlanForm({required this.service, required this.plan});

  final AdminService service;
  final Map<String, dynamic> plan;

  @override
  State<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<_PlanForm> {
  late final bool _free = widget.plan['esGratuito'] == true;
  late final TextEditingController _name = TextEditingController(text: str(widget.plan['nombre']));
  late final TextEditingController _price =
      TextEditingController(text: '${asNum(widget.plan['precio']).toInt()}');
  late final TextEditingController _days =
      TextEditingController(text: '${asNum(widget.plan['duracionDias']).toInt()}');
  late final TextEditingController _benefits =
      TextEditingController(text: asStrings(widget.plan['beneficios']).join('\n'));

  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _days.dispose();
    _benefits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int? days = int.tryParse(_days.text.trim());
    final int price = int.tryParse(_price.text.trim()) ?? 0;

    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Escribe el nombre del plan');
      return;
    }
    if (days == null || days < 1) {
      setState(() => _error = 'La duración debe ser de al menos 1 día');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      await widget.service.updatePlan(str(widget.plan['_id']), <String, dynamic>{
        'nombre': _name.text.trim(),
        'precio': _free ? 0 : price,
        'duracionDias': days,
        'beneficios': <String>[
          for (final String line in _benefits.text.split('\n'))
            if (line.trim().isNotEmpty) line.trim(),
        ],
      });
      if (!mounted) return;
      adminToast(context, 'Plan actualizado');
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
      title: 'Editar plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminTextField(controller: _name, label: 'Nombre', maxLength: 60),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: AdminTextField(
                  controller: _price,
                  label: _free ? 'Precio (siempre 0)' : 'Precio (COP)',
                  digitsOnly: true,
                  maxLength: 9,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminTextField(
                  controller: _days,
                  label: 'Duración (días)',
                  digitsOnly: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _benefits,
            label: 'Beneficios (uno por línea, máximo 12)',
            maxLines: 6,
          ),
          if (_error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(_error, style: AppText.body(size: 13, color: AppColors.red)),
          ],
          const SizedBox(height: 20),
          AdminButton(
            label: 'Guardar cambios',
            kind: AdminButtonKind.primary,
            loading: _saving,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}