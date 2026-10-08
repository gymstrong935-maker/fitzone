import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/personal_info.dart';
import '../widgets/fz_label.dart';
import '../widgets/fz_number_field.dart';
import '../widgets/fz_select.dart';
import '../widgets/fz_slider.dart';
import '../widgets/fz_text_area.dart';
import '../widgets/step_header.dart';

/// Paso "Información Personal".
class PersonalInfoStep extends StatelessWidget {
  const PersonalInfoStep({
    super.key,
    required this.info,
    required this.onChanged,
  });

  final PersonalInfo info;
  final ValueChanged<PersonalInfo> onChanged;

  static const double _lbPerKg = 2.20462;

  // ── Peso ──────────────────────────────────────────────────────────────────

  void _changeUnit(WeightUnit unit) {
    double weight = info.weight;
    if (info.weightUnit == WeightUnit.kg && unit == WeightUnit.lb) {
      weight = weight * _lbPerKg;
    } else if (info.weightUnit == WeightUnit.lb && unit == WeightUnit.kg) {
      weight = weight / _lbPerKg;
    }
    weight = (weight * 10).round() / 10;
    onChanged(info.copyWith(weight: weight, weightUnit: unit));
  }

  String get _approxWeight {
    if (info.weightUnit == WeightUnit.kg) {
      final double lb = (info.weight * _lbPerKg * 10).round() / 10;
      return '≈ ${formatNumber(lb)} lb';
    }
    final double kg = (info.weight / _lbPerKg * 10).round() / 10;
    return '≈ ${formatNumber(kg)} kg';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const StepHeader(
          icon: Icons.person_outline_rounded,
          title: 'Información Personal',
          subtitle: 'Cuéntanos sobre ti para personalizar tu experiencia',
          teal: true,
        ),
        const SizedBox(height: 24),
        _buildAgeAndGender(),
        const SizedBox(height: 16),
        _buildWeight(),
        const SizedBox(height: 16),
        _buildHeight(),
        const SizedBox(height: 24),
        _buildSliders(),
        const SizedBox(height: 12),
        _buildMedical(),
      ],
    );
  }

  Widget _buildAgeAndGender() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const FzLabel('Edad'),
              const SizedBox(height: 6),
              FzNumberField(
                value: info.age.toDouble(),
                min: 10,
                onChanged: (double v) =>
                    onChanged(info.copyWith(age: v.round())),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const FzLabel('Género'),
              const SizedBox(height: 6),
              FzSelect<Gender>(
                value: info.gender,
                options: const <FzSelectOption<Gender>>[
                  FzSelectOption<Gender>(
                    value: Gender.male,
                    label: 'Masculino',
                  ),
                  FzSelectOption<Gender>(
                    value: Gender.female,
                    label: 'Femenino',
                  ),
                  FzSelectOption<Gender>(value: Gender.other, label: 'Otro'),
                ],
                onChanged: (Gender g) => onChanged(info.copyWith(gender: g)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const FzLabel('Peso'),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: FzNumberField(
                value: info.weight,
                min: 20,
                decimal: true,
                onChanged: (double v) => onChanged(info.copyWith(weight: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FzSelect<WeightUnit>(
                value: info.weightUnit,
                options: const <FzSelectOption<WeightUnit>>[
                  FzSelectOption<WeightUnit>(
                    value: WeightUnit.kg,
                    label: 'kg',
                  ),
                  FzSelectOption<WeightUnit>(
                    value: WeightUnit.lb,
                    label: 'lb',
                  ),
                ],
                onChanged: _changeUnit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _approxWeight,
          style: AppText.body(
            size: 12,
            color: const Color.fromRGBO(34, 211, 238, 0.7),
            height: 1.333,
          ),
        ),
      ],
    );
  }

  Widget _buildHeight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const FzLabel('Estatura (cm)'),
        const SizedBox(height: 6),
        FzNumberField(
          value: info.height.toDouble(),
          min: 100,
          onChanged: (double v) => onChanged(info.copyWith(height: v.round())),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    final PsychologicalCondition psy = info.psychologicalCondition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FzSliderField(
          label: 'Condición Física',
          value: info.physicalCondition,
          gap: 12,
          onChanged: (int v) => onChanged(info.copyWith(physicalCondition: v)),
        ),
        const SizedBox(height: 12),
        FzSliderField(
          label: 'Motivación',
          value: psy.motivation,
          onChanged: (int v) => onChanged(
            info.copyWith(psychologicalCondition: psy.copyWith(motivation: v)),
          ),
        ),
        const SizedBox(height: 12),
        FzSliderField(
          label: 'Nivel de Estrés',
          value: psy.stress,
          onChanged: (int v) => onChanged(
            info.copyWith(psychologicalCondition: psy.copyWith(stress: v)),
          ),
        ),
        const SizedBox(height: 12),
        FzSliderField(
          label: 'Energía',
          value: psy.energy,
          onChanged: (int v) => onChanged(
            info.copyWith(psychologicalCondition: psy.copyWith(energy: v)),
          ),
        ),
      ],
    );
  }

  Widget _buildMedical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const FzLabel('Condiciones Médicas (opcional)'),
        const SizedBox(height: 6),
        FzTextArea(
          initialText: info.medicalConditions.physical,
          hint: 'Lesiones, condiciones crónicas, alergias...',
          onChanged: (String text) => onChanged(
            info.copyWith(
              medicalConditions:
                  info.medicalConditions.copyWith(physical: text),
            ),
          ),
        ),
      ],
    );
  }
}