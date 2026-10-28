import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/measurement_guides.dart';
import '../models/body_measurements.dart';
import '../widgets/fz_optional_number_field.dart';
import '../widgets/measure_guide_sheet.dart';
import '../widgets/step_header.dart';

/// Paso "Mediciones Corporales" (circunferencias y plicometría).
///
/// No muestra avisos de "obligatorio": solo resalta en rojo las circunferencias
/// vacías cuando [showErrors] es `true` (la persona intentó continuar).
class MeasurementsStep extends StatelessWidget {
  const MeasurementsStep({
    super.key,
    required this.measurements,
    required this.onChanged,
    this.showErrors = false,
    this.showLaterNote = true,
  });

  final BodyMeasurements measurements;
  final ValueChanged<BodyMeasurements> onChanged;

  /// Resalta en rojo las circunferencias que faltan.
  final bool showErrors;

  /// Muestra el aviso "podrás modificarlos después" (solo en el registro).
  final bool showLaterNote;

  static Color get _teal400 => AppColors.teal400;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StepHeader(
          icon: Icons.straighten_rounded,
          title: 'Mediciones Corporales',
          subtitle: showLaterNote
              ? 'Con estas medidas seguimos tu progreso. Toca el ? para ver cómo tomar cada una.'
              : 'Toca el ? bajo cada medida para ver cómo tomarla.',
        ),
        const SizedBox(height: 24),
        if (showLaterNote) ...<Widget>[
          _buildInfoBox(),
          const SizedBox(height: 20),
        ],
        _buildCircumferences(),
        const SizedBox(height: 24),
        _buildSkinfolds(),
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
        'Podrás modificar estos datos más adelante desde Ajustes.',
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
        guide: kSkinfoldGuides[site],
        onChanged: (double? v) => onChanged(measurements.withSkinfold(site, v)),
      );
    }

    return _Section(
      icon: Icons.monitor_heart_outlined,
      title: 'Plicometría (mm) · opcional',
      color: AppColors.cyanLight,
      cells: <Widget>[
        cell(SkinfoldSite.triceps, 'Tríceps'),
        cell(SkinfoldSite.subscapular, 'Subescapular'),
        cell(SkinfoldSite.chest, 'Pecho'),
        cell(SkinfoldSite.abdominal, 'Abdominal'),
        cell(SkinfoldSite.thigh, 'Muslo'),
        cell(SkinfoldSite.suprailiac, 'Suprailíaco'),
        cell(SkinfoldSite.midaxillary, 'Axilar medio'),
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
        guide: kCircumferenceGuides[site],
        error: showErrors && (measurements.circumferences[site] ?? 0) <= 0,
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
    this.guide,
    this.error = false,
  });

  final String label;
  final String hint;
  final double? value;
  final ValueChanged<double?> onChanged;

  /// Instrucciones para tomar esta medida (botón "?").
  final MeasureGuide? guide;
  final bool error;

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
        FzOptionalNumberField(
          value: value,
          hint: hint,
          error: error,
          onChanged: onChanged,
        ),
        if (guide != null)
          Align(
            alignment: Alignment.centerLeft,
            child: MeasureHelpButton(guide: guide!),
          ),
      ],
    );
  }
}