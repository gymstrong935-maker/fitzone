import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/error_box.dart';
import '../../onboarding/widgets/fz_field_frame.dart';
import '../../onboarding/widgets/fz_label.dart';
import '../models/nutrition_models.dart';

/// Abre la hoja inferior "Agregar comida". [onSubmit] debe guardar la comida
/// y lanzar [ApiException] si el servidor la rechaza.
Future<void> showAddMealSheet(
  BuildContext context, {
  required Future<void> Function(NewMeal meal) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000),
    constraints: const BoxConstraints(maxWidth: 512),
    builder: (BuildContext ctx) => _AddMealSheet(onSubmit: onSubmit),
  );
}

String _two(int n) => n.toString().padLeft(2, '0');

MealType _defaultType() {
  final int hour = DateTime.now().hour;
  if (hour < 11) return MealType.breakfast;
  if (hour < 16) return MealType.lunch;
  if (hour < 19) return MealType.snack;
  return MealType.dinner;
}

class _FoodRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController amount = TextEditingController();

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet({required this.onSubmit});

  final Future<void> Function(NewMeal meal) onSubmit;

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  MealType _type = _defaultType();
  TimeOfDay _time = TimeOfDay.now();
  final List<_FoodRow> _rows = <_FoodRow>[_FoodRow()];

  final TextEditingController _calories = TextEditingController();
  final TextEditingController _protein = TextEditingController();
  final TextEditingController _carbs = TextEditingController();
  final TextEditingController _fats = TextEditingController();

  String _error = '';
  bool _saving = false;

  @override
  void dispose() {
    for (final _FoodRow r in _rows) {
      r.dispose();
    }
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fats.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final List<Food> foods = <Food>[
      for (final _FoodRow r in _rows)
        if (r.name.text.trim().isNotEmpty)
          Food(name: r.name.text.trim(), amount: r.amount.text.trim()),
    ];
    final int? calories = int.tryParse(_calories.text.trim());

    if (foods.isEmpty) {
      setState(() => _error = 'Agrega al menos un alimento');
      return;
    }
    if (calories == null || calories <= 0) {
      setState(() => _error = 'Escribe las calorías de la comida');
      return;
    }

    setState(() {
      _error = '';
      _saving = true;
    });

    try {
      await widget.onSubmit(
        NewMeal(
          type: _type,
          time: '${_two(_time.hour)}:${_two(_time.minute)}',
          foods: foods,
          calories: calories,
          protein: int.tryParse(_protein.text.trim()) ?? 0,
          carbs: int.tryParse(_carbs.text.trim()) ?? 0,
          fats: int.tryParse(_fats.text.trim()) ?? 0,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo guardar la comida. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glass(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.whiteA(0.10))),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.whiteA(0.20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Agregar comida',
                  style: AppText.display(size: 20, weight: FontWeight.w700, height: 1.4),
                ),
                const SizedBox(height: 2),
                Text(
                  'Se suma a lo que llevas hoy',
                  style: AppText.body(size: 14, color: AppColors.whiteA(0.50), height: 1.43),
                ),
                const SizedBox(height: 20),

                // ── Tipo y hora ──
                const FzLabel('Comida'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final MealType t in MealType.values)
                      _TypeChip(
                        label: t.label,
                        selected: _type == t,
                        onTap: () => setState(() => _type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const FzLabel('Hora'),
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickTime,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.whiteA(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.whiteA(0.15)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.schedule_rounded, size: 16, color: AppColors.whiteA(0.5)),
                        const SizedBox(width: 10),
                        Text(
                          '${_two(_time.hour)}:${_two(_time.minute)}',
                          style: AppText.body(size: 15, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Alimentos ──
                const FzLabel('Alimentos'),
                const SizedBox(height: 8),
                for (int i = 0; i < _rows.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: _Field(
                          controller: _rows[i].name,
                          hint: 'Ej. Avena',
                          capitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _Field(
                          controller: _rows[i].amount,
                          hint: '80 g',
                        ),
                      ),
                      if (_rows.length > 1)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            _rows.removeAt(i).dispose();
                          }),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.whiteA(0.40),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _rows.length >= 15
                      ? null
                      : () => setState(() => _rows.add(_FoodRow())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.add_rounded, size: 18, color: AppColors.cyanText),
                        const SizedBox(width: 6),
                        Text(
                          'Agregar otro alimento',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.cyanText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Calorías y macros ──
                const FzLabel('Calorías'),
                const SizedBox(height: 6),
                _Field(
                  controller: _calories,
                  hint: 'kcal totales de la comida',
                  digitsOnly: true,
                  maxLength: 4,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: _MacroInput(label: 'Proteína (g)', controller: _protein)),
                    const SizedBox(width: 10),
                    Expanded(child: _MacroInput(label: 'Carbos (g)', controller: _carbs)),
                    const SizedBox(width: 10),
                    Expanded(child: _MacroInput(label: 'Grasas (g)', controller: _fats)),
                  ],
                ),
                if (_error.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  ErrorBox(_error),
                ],
                const SizedBox(height: 20),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _saving ? null : _save,
                  child: AnimatedOpacity(
                    opacity: _saving ? 0.6 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: <Color>[AppColors.cyan, AppColors.teal],
                        ),
                      ),
                      child: Text(
                        _saving ? 'Guardando...' : 'Guardar comida',
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: const Color(0xFF0A0A0A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? AppColors.cyanA(0.22) : AppColors.whiteA(0.06),
            border: Border.all(
              color: selected ? AppColors.cyanA(0.55) : AppColors.whiteA(0.10),
            ),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w600,
              color: selected ? AppColors.cyanText : AppColors.whiteA(0.70),
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroInput extends StatelessWidget {
  const _MacroInput({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: AppText.body(
            size: 12,
            weight: FontWeight.w500,
            color: AppColors.whiteA(0.60),
            height: 1.333,
          ),
        ),
        const SizedBox(height: 4),
        _Field(controller: controller, hint: '0', digitsOnly: true, maxLength: 3),
      ],
    );
  }
}

/// Campo de texto con el marco del diseño (anillo cian al enfocar).
class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.digitsOnly = false,
    this.maxLength,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final bool digitsOnly;
  final int? maxLength;
  final TextCapitalization capitalization;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FzFieldFrame(
      focused: _focus.hasFocus,
      height: 44,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.digitsOnly ? TextInputType.number : TextInputType.text,
        textCapitalization: widget.capitalization,
        inputFormatters: <TextInputFormatter>[
          if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (widget.maxLength != null)
            LengthLimitingTextInputFormatter(widget.maxLength),
          if (!widget.digitsOnly && widget.maxLength == null)
            LengthLimitingTextInputFormatter(60),
        ],
        cursorColor: AppColors.ink,
        style: AppText.body(size: 15, color: AppColors.ink),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hint,
          hintStyle: AppText.body(size: 15, color: AppColors.whiteA(0.35)),
        ),
      ),
    );
  }
}