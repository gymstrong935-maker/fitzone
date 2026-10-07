import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../onboarding/widgets/fz_field_frame.dart';
import '../models/workout_log.dart';
import '../workout_format.dart';

/// Resumen final: duración, ejercicios y kcal, más el formulario
/// "Post-Entrenamiento" (pulsaciones, fatiga y agujetas).
class WorkoutSummaryView extends StatefulWidget {
  const WorkoutSummaryView({
    super.key,
    required this.workoutSeconds,
    required this.completed,
    required this.total,
    required this.onSave,
  });

  final int workoutSeconds;
  final int completed;
  final int total;
  final void Function(
    int? restingHeartRate,
    FatigueLevel fatigue,
    SorenessLevel soreness,
  ) onSave;

  @override
  State<WorkoutSummaryView> createState() => _WorkoutSummaryViewState();
}

class _WorkoutSummaryViewState extends State<WorkoutSummaryView> {
  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _teal400 = Color(0xFF2DD4BF);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _pink400 = Color(0xFFF472B6);

  int? _heartRate;
  FatigueLevel _fatigue = FatigueLevel.moderate;
  SorenessLevel _soreness = SorenessLevel.light;

  @override
  Widget build(BuildContext context) {
    final int kcal = (widget.workoutSeconds / 60 * 8).round();

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 512),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHero(),
                const SizedBox(height: 32),
                _buildSummaryCard(kcal),
                const SizedBox(height: 16),
                _buildPostWorkoutCard(),
                const SizedBox(height: 20),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Encabezado ────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double v, Widget? child) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
        );
      },
      child: Column(
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.cyan, AppColors.teal],
              ),
            ),
            child: const Icon(Icons.check_rounded, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Entrenamiento Completado!',
            textAlign: TextAlign.center,
            style: AppText.display(
              size: 24,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1.333,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Excelente trabajo hoy 💪',
            style: AppText.body(
              size: 14,
              color: AppColors.whiteA(0.50),
              height: 1.43,
            ),
          ),
        ],
      ),
    );
  }

  // ── Resumen ───────────────────────────────────────────────────────────────
  Widget _buildSummaryCard(int kcal) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _cardTitle('Resumen'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _SummaryValue(
                  value: formatWorkoutTime(widget.workoutSeconds),
                  label: 'Duración',
                  color: _cyan400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryValue(
                  value: '${widget.completed}/${widget.total}',
                  label: 'Ejercicios',
                  color: _teal400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryValue(
                  value: '~$kcal',
                  label: 'kcal',
                  color: _orange400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Post-entrenamiento ────────────────────────────────────────────────────
  Widget _buildPostWorkoutCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _cardTitle('Post-Entrenamiento'),
          const SizedBox(height: 20),

          // Pulsaciones.
          _fieldLabel('Pulsaciones en reposo (opcional)'),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.favorite_border_rounded, size: 16, color: _pink400),
              const SizedBox(width: 8),
              Expanded(
                child: _HeartRateField(
                  onChanged: (int? value) => _heartRate = value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Fatiga.
          _fieldLabel('Nivel de Fatiga'),
          const SizedBox(height: 8),
          _OptionGrid<FatigueLevel>(
            selected: _fatigue,
            selectedBackground: AppColors.cyanA(0.25),
            selectedBorder: AppColors.cyanA(0.5),
            onSelect: (FatigueLevel v) => setState(() => _fatigue = v),
            options: const <_Option<FatigueLevel>>[
              _Option<FatigueLevel>(FatigueLevel.none, '😊', 'Sin fatiga'),
              _Option<FatigueLevel>(FatigueLevel.moderate, '😌', 'Moderada'),
              _Option<FatigueLevel>(FatigueLevel.fatigued, '😓', 'Fatigado'),
              _Option<FatigueLevel>(FatigueLevel.high, '😰', 'Alto'),
              _Option<FatigueLevel>(FatigueLevel.veryHigh, '😵', 'Muy alto'),
            ],
          ),
          const SizedBox(height: 20),

          // Agujetas.
          _fieldLabel('Agujetas'),
          const SizedBox(height: 8),
          _OptionGrid<SorenessLevel>(
            selected: _soreness,
            selectedBackground: AppColors.tealA(0.25),
            selectedBorder: AppColors.tealA(0.5),
            onSelect: (SorenessLevel v) => setState(() => _soreness = v),
            options: const <_Option<SorenessLevel>>[
              _Option<SorenessLevel>(SorenessLevel.none, '💪', 'Sin dolor'),
              _Option<SorenessLevel>(SorenessLevel.light, '😊', 'Ligero'),
              _Option<SorenessLevel>(SorenessLevel.moderate, '😅', 'Moderado'),
              _Option<SorenessLevel>(SorenessLevel.intense, '😣', 'Intenso'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSave(_heartRate, _fatigue, _soreness),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: <Color>[AppColors.cyan, AppColors.teal],
          ),
        ),
        child: Text(
          'Guardar y Finalizar',
          style: AppText.body(
            size: 16,
            weight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: AppText.body(
        size: 14,
        weight: FontWeight.w600,
        color: AppColors.whiteA(0.70),
        letterSpacing: 0.35,
        height: 1.43,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: AppText.body(
        size: 12,
        weight: FontWeight.w500,
        color: AppColors.whiteA(0.70),
        height: 1.333,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: child,
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: AppText.display(
            size: 24,
            weight: FontWeight.w700,
            color: color,
            height: 1.333,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.45),
            height: 1.333,
          ),
        ),
      ],
    );
  }
}

/// Campo de pulsaciones (solo números, hasta 3 dígitos).
class _HeartRateField extends StatefulWidget {
  const _HeartRateField({required this.onChanged});

  final ValueChanged<int?> onChanged;

  @override
  State<_HeartRateField> createState() => _HeartRateFieldState();
}

class _HeartRateFieldState extends State<_HeartRateField> {
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
      height: 40,
      child: TextField(
        focusNode: _focus,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onChanged: (String text) => widget.onChanged(int.tryParse(text)),
        cursorColor: Colors.white,
        style: AppText.body(size: 15, color: Colors.white),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'BPM',
          hintStyle: AppText.body(size: 15, color: AppColors.whiteA(0.60)),
        ),
      ),
    );
  }
}

class _Option<T> {
  const _Option(this.value, this.emoji, this.label);

  final T value;
  final String emoji;
  final String label;
}

/// Fila de botones con emoji y etiqueta pequeña (fatiga y agujetas).
class _OptionGrid<T> extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.onSelect,
  });

  final List<_Option<T>> options;
  final T selected;
  final Color selectedBackground;
  final Color selectedBorder;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < options.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _buildOption(options[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(_Option<T> option) {
    final bool isSelected = option.value == selected;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(option.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? selectedBackground : AppColors.whiteA(0.07),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? selectedBorder : AppColors.whiteA(0.10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(option.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 9,
                    color: AppColors.whiteA(0.55),
                    height: 1.25,
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