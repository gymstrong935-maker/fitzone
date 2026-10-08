import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/body_measurements.dart';
import '../widgets/fz_optional_number_field.dart';
import '../widgets/step_header.dart';

/// Paso "Mediciones Corporales" (opcional, para todos los planes).
class MeasurementsStep extends StatelessWidget {
  const MeasurementsStep({
    super.key,
    required this.measurements,
    required this.onChanged,
  });

  final BodyMeasurements measurements;
  final ValueChanged<BodyMeasurements> onChanged;

  static const Color _teal400 = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const StepHeader(
          icon: Icons.straighten_rounded,
          title: 'Mediciones Corporales',
          subtitle: 'Opcionales — te ayudan a ver tu progreso real',
        ),
        const SizedBox(height: 24),
        _buildInfoBox(),
        const SizedBox(height: 20),
        _buildSkinfolds(),
        const SizedBox(height: 20),
        _buildCircumferences(),
      ],
    );
  }

  // ── Aviso superior ────────────────────────────────────────────────────────
  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cyanA(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyanA(0.18)),
      ),
      child: Text(
        'Puedes omitir esto y completarlo más tarde en tu perfil',
        textAlign: TextAlign.center,
        style: AppText.body(
          size: 12,
          color: const Color.fromRGBO(34, 211, 238, 0.8),
          height: 1.333,
        ),
      ),
    );
  }

  // ── Plicometría ───────────────────────────────────────────────────────────
  Widget _buildSkinfolds() {
    Widget cell(SkinfoldSite site, String label) {
      return _MeasureCell(
        label: label,
        hint: 'mm',
        value: measurements.skinfolds[site],
        onChanged: (double? v) => onChanged(measurements.withSkinfold(site, v)),
      );
    }

    return _Section(
      icon: Icons.monitor_heart_outlined,
      title: 'Plicometría (mm)',
      color: AppColors.cyanLight,
      cells: <Widget>[
        cell(SkinfoldSite.triceps, 'Tríceps'),
        cell(SkinfoldSite.subscapular, 'Subescapular'),
        cell(SkinfoldSite.chest, 'Pecho'),
        cell(SkinfoldSite.abdominal, 'Abdominal'),
        cell(SkinfoldSite.thigh, 'Muslo'),
        cell(SkinfoldSite.suprailiac, 'Suprailíaco'),
      ],
    );
  }

  // ── Circunferencias ───────────────────────────────────────────────────────
  Widget _buildCircumferences() {
    Widget cell(CircumferenceSite site, String label) {
      return _MeasureCell(
        label: label,
        hint: 'cm',
        value: measurements.circumferences[site],
        onChanged: (double? v) =>
            onChanged(measurements.withCircumference(site, v)),
      );
    }

    return _Section(
      icon: Icons.straighten_rounded,
      title: 'Circunferencias (cm)',
      color: _teal400,
      cells: <Widget>[
        cell(CircumferenceSite.arm, 'Brazo'),
        cell(CircumferenceSite.chest, 'Pecho'),
        cell(CircumferenceSite.waist, 'Cintura'),
        cell(CircumferenceSite.hip, 'Cadera'),
        cell(CircumferenceSite.thigh, 'Muslo'),
        cell(CircumferenceSite.calf, 'Pantorrilla'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

/// Título con ícono + cuadrícula de 2 columnas.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.color,
    required this.cells,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: cells[i]),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < cells.length ? cells[i + 1] : const SizedBox(),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppText.display(
                size: 14,
                weight: FontWeight.w600,
                color: color,
                height: 1.43,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }
}

/// Etiqueta pequeña + campo numérico opcional.
class _MeasureCell extends StatelessWidget {
  const _MeasureCell({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final double? value;
  final ValueChanged<double?> onChanged;

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
            color: AppColors.whiteA(0.6),
            height: 1.333,
          ),
        ),
        const SizedBox(height: 4),
        FzOptionalNumberField(value: value, hint: hint, onChanged: onChanged),
      ],
    );
  }
}