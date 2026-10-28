import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_exception.dart';
import '../../core/services/measurements_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/error_box.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../history/workouts_controller.dart';
import '../home/widgets/home_card.dart';
import '../onboarding/models/onboarding_data.dart';
import '../onboarding/models/personal_info.dart';
import 'data/stats_data.dart';
import 'stats_controller.dart';
import 'widgets/stats_charts.dart';

enum StatsTab { weight, activity, body }

/// Pantalla "Estadísticas" (pestaña de la barra inferior).
///
/// Todo sale de datos reales:
/// · Peso y Cuerpo: mediciones guardadas en el servidor (si todavía no hay,
///   los datos del registro).
/// · Actividad y racha: los entrenamientos terminados.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.stats,
    required this.workouts,
    required this.onboarding,
    required this.weeklyGoal,
    required this.onWeightLogged,
  });

  final StatsController stats;
  final WorkoutsController workouts;

  /// Datos del registro: respaldo y datos como edad, sexo o estatura.
  final OnboardingData onboarding;

  /// Entrenamientos por semana que la persona se propuso.
  final int weeklyGoal;

  /// Se llama (con los kg) cuando se registra un peso nuevo.
  final ValueChanged<double> onWeightLogged;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static Color get _cyan400 => AppColors.cyanLightText;
  static Color get _teal400 => AppColors.teal400;
  static Color get _orange400 => AppColors.orange;
  static Color get _purple400 => AppColors.purple;

  StatsTab _tab = StatsTab.weight;

  @override
  void initState() {
    super.initState();
    // Al abrir la pantalla se trae lo más reciente.
    unawaited(widget.stats.load(silent: true));
    unawaited(widget.workouts.refresh(silent: true));
  }

  Future<void> _refresh() async {
    await Future.wait<void>(<Future<void>>[
      widget.stats.load(),
      widget.workouts.refresh(),
    ]);
  }

  /// Mediciones reales; si el servidor aún no tiene ninguna, la que salió del
  /// registro de la persona.
  List<BodyRecord> _records() {
    final List<BodyRecord> saved = widget.stats.records;
    if (saved.isNotEmpty) return saved;
    return <BodyRecord>[recordFromOnboarding(widget.onboarding, DateTime.now())];
  }

  @override
  Widget build(BuildContext context) {
    final double top = 24 + MediaQuery.paddingOf(context).top;
    final double bottom = 96 + MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[widget.stats, widget.workouts]),
      builder: (BuildContext context, Widget? _) {
        final List<BodyRecord> records = _records();
        final PersonalInfo info = widget.onboarding.personalInfo;
        final List<StatKpi> kpis = buildKpis(
          records,
          age: info.age < 10 ? 25 : info.age,
          gender: info.gender,
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: top, bottom: bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildHeader(),
                      const SizedBox(height: 24),
                      if (widget.stats.error != null &&
                          widget.stats.records.isEmpty) ...<Widget>[
                        ErrorBox(
                          '${widget.stats.error} Mostramos los datos de tu registro.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildKpiGrid(kpis),
                      const SizedBox(height: 16),
                      _buildTabs(),
                      const SizedBox(height: 16),
                      _buildPanel(records),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        duration: const Duration(milliseconds: 400),
                        offsetY: 10,
                        child: _buildStreakBanner(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Cabecera ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'PROGRESO',
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.40),
            letterSpacing: 1.2,
            height: 1.333,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Estadísticas',
          style: AppText.display(
            size: 24,
            weight: FontWeight.w700,
            letterSpacing: -0.48,
            height: 1.333,
          ),
        ),
      ],
    );
  }

  // ── Indicadores (2 columnas) ──────────────────────────────────────────────
  Widget _buildKpiGrid(List<StatKpi> kpis) {
    Widget cell(int i) {
      return FadeSlideIn(
        delay: Duration(milliseconds: i * 60),
        duration: const Duration(milliseconds: 400),
        offsetY: 12,
        child: _KpiCard(kpi: kpis[i]),
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < kpis.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: cell(i)),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < kpis.length ? cell(i + 1) : const SizedBox(),
            ),
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  // ── Selector de pestañas ──────────────────────────────────────────────────
  Widget _buildTabs() {
    const List<(StatsTab, String)> tabs = <(StatsTab, String)>[
      (StatsTab.weight, 'Peso'),
      (StatsTab.activity, 'Actividad'),
      (StatsTab.body, 'Cuerpo'),
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < tabs.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          _TabChip(
            label: tabs[i].$2,
            selected: _tab == tabs[i].$1,
            onTap: () => setState(() => _tab = tabs[i].$1),
          ),
        ],
      ],
    );
  }

  // ── Panel que cambia según la pestaña ─────────────────────────────────────
  Widget _buildPanel(List<BodyRecord> records) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      reverseDuration: Duration.zero,
      layoutBuilder: (Widget? current, List<Widget> previous) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previous, if (current != null) current],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (BuildContext context, Widget? c) {
              return Transform.translate(
                offset: Offset(0, (1 - animation.value) * 10),
                child: c,
              );
            },
          ),
        );
      },
      child: switch (_tab) {
        StatsTab.weight => _buildWeightPanel(records),
        StatsTab.activity => _buildActivityPanel(),
        StatsTab.body => _buildBodyPanel(records),
      },
    );
  }

  Widget _panelHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required String trailing,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: AppText.display(
                  size: 16,
                  weight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.body(
                  size: 12,
                  color: AppColors.whiteA(0.40),
                  height: 1.333,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              trailing,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w700,
                color: color,
                height: 1.43,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Pestaña: Peso ─────────────────────────────────────────────────────────
  Widget _buildWeightPanel(List<BodyRecord> records) {
    final List<WeightPoint> points = buildWeightPoints(records);
    final double change = weightChange(records);
    final bool onlyFromSignup = widget.stats.records.isEmpty;

    final IconData icon = change.abs() < 0.05
        ? Icons.trending_flat_rounded
        : change > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;
    final String trailing =
        change.abs() < 0.05 ? 'Sin cambios' : '${formatSigned(change)} kg';
    final String subtitle = points.length <= 1
        ? 'Última medición'
        : 'Últimas ${points.length} mediciones';

    return HomeCard(
      key: const ValueKey<String>('panel-weight'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panelHeader(
            title: 'Peso Corporal',
            subtitle: subtitle,
            icon: icon,
            trailing: trailing,
            color: _cyan400,
          ),
          const SizedBox(height: 16),
          WeightAreaChart(data: points),
          if (onlyFromSignup) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Aún no hay mediciones guardadas: se muestra el peso de tu registro.',
              style: AppText.body(
                size: 12,
                color: AppColors.whiteA(0.40),
                height: 1.333,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _AddWeightButton(onTap: () => _openWeightSheet(records.last)),
        ],
      ),
    );
  }

  // ── Pestaña: Actividad ────────────────────────────────────────────────────
  Widget _buildActivityPanel() {
    final WorkoutsController w = widget.workouts;
    final List<ActivityPoint> data = buildActivity(w.minutesByWeekday);
    final int sessions = w.sessionsThisWeek;
    final int minutes = w.minutesThisWeek;
    final int kcal = w.caloriesThisWeek;
    final int compliance = compliancePercent(sessions, widget.weeklyGoal);

    return HomeCard(
      key: const ValueKey<String>('panel-activity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panelHeader(
            title: 'Tiempo de Entrenamiento',
            subtitle: 'Esta semana · minutos',
            icon: Icons.monitor_heart_outlined,
            trailing: '$minutes min',
            color: _teal400,
          ),
          const SizedBox(height: 16),
          ActivityBarChart(data: data),
          if (sessions == 0) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Todavía no has entrenado esta semana. Tu primer entrenamiento aparecerá aquí.',
              style: AppText.body(
                size: 12,
                color: AppColors.whiteA(0.40),
                height: 1.333,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.whiteA(0.07))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _SummaryChip(value: '$sessions', label: 'sesiones', color: _cyan400),
                _SummaryChip(value: '$minutes', label: 'minutos', color: _teal400),
                _SummaryChip(value: '$kcal', label: 'kcal', color: _orange400),
                _SummaryChip(
                  value: '$compliance%',
                  label: 'cumplimiento',
                  color: _purple400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pestaña: Cuerpo ───────────────────────────────────────────────────────
  Widget _buildBodyPanel(List<BodyRecord> records) {
    final List<CircumferenceStat> stats = buildCircumferences(records);

    return HomeCard(
      key: const ValueKey<String>('panel-body'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Circunferencias Corporales',
            style: AppText.display(
              size: 16,
              weight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            records.length > 1 ? 'vs. medición anterior' : 'Primera medición',
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.40),
              height: 1.333,
            ),
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty)
            Text(
              'Aún no hay medidas guardadas. Puedes agregarlas desde Ajustes → Datos personales.',
              style: AppText.body(
                size: 14,
                color: AppColors.whiteA(0.55),
                height: 1.43,
              ),
            )
          else
            for (int i = 0; i < stats.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              _CircumferenceRow(stat: stats[i], index: i),
            ],
        ],
      ),
    );
  }

  // ── Banner de racha ───────────────────────────────────────────────────────
  Widget _buildStreakBanner() {
    final int streak = widget.workouts.currentStreak;
    final String title = streak == 0
        ? 'Empieza tu racha'
        : 'Racha de $streak ${streak == 1 ? 'día' : 'días'}';
    final String message = streak == 0
        ? 'Completa un entrenamiento hoy para iniciarla.'
        : streak == 1
            ? 'Entrenaste hoy. ¡Mañana suma el segundo día!'
            : 'Llevas $streak días seguidos entrenando. ¡Increíble!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.fromRGBO(6, 182, 212, 0.12),
            Color.fromRGBO(20, 184, 166, 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanA(0.22)),
      ),
      child: Row(
        children: <Widget>[
          const Text('🔥', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppText.body(
                    size: 12,
                    color: AppColors.whiteA(0.50),
                    height: 1.333,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$streak',
            style: AppText.display(
              size: 24,
              weight: FontWeight.w700,
              color: _cyan400,
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }

  // ── Registrar peso ────────────────────────────────────────────────────────
  Future<void> _openWeightSheet(BodyRecord latest) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final double? saved = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xBF000000),
      constraints: const BoxConstraints(maxWidth: 512),
      builder: (BuildContext ctx) => _WeightSheet(
        latest: latest,
        onSave: (double kg) => widget.stats.logWeight(kg, base: latest),
      ),
    );

    if (saved == null || !mounted) return;
    widget.onWeightLogged(saved);
    messenger.showSnackBar(
      SnackBar(content: Text('Peso guardado: ${formatStat(saved)} kg')),
    );
  }
}

/// Botón "Registrar peso" bajo la gráfica.
class _AddWeightButton extends StatelessWidget {
  const _AddWeightButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Registrar peso',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cyanA(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cyanA(0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.add_rounded, size: 18, color: AppColors.cyanText),
              const SizedBox(width: 6),
              Text(
                'Registrar peso de hoy',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.cyanText,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior para escribir el peso de hoy.
class _WeightSheet extends StatefulWidget {
  const _WeightSheet({required this.latest, required this.onSave});

  final BodyRecord latest;

  /// Guarda el peso (en kg). Lanza `ApiException` si falla.
  final Future<BodyRecord> Function(double kg) onSave;

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  static const double _lbPerKg = 2.20462;

  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  bool get _pounds => widget.latest.usesPounds;
  String get _unit => _pounds ? 'lb' : 'kg';

  @override
  void initState() {
    super.initState();
    final double shown =
        _pounds ? widget.latest.kg * _lbPerKg : widget.latest.kg;
    _controller = TextEditingController(text: formatStat(shown));
    _controller.selection =
        TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final double? typed =
        double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (typed == null) {
      setState(() => _error = 'Escribe tu peso en números.');
      return;
    }

    final double kg = _pounds ? typed / _lbPerKg : typed;
    if (kg < 20 || kg > 300) {
      setState(() => _error = 'Escribe un peso entre 20 y 300 kg.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final double rounded = double.parse(kg.toStringAsFixed(1));
      await widget.onSave(rounded);
      if (!mounted) return;
      Navigator.of(context).pop(rounded);
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
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.whiteA(0.10)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.whiteA(0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Registrar peso',
              style: AppText.display(
                size: 20,
                weight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Se guarda con la fecha de hoy y actualiza tus estadísticas.',
              style: AppText.body(
                size: 14,
                color: AppColors.whiteA(0.55),
                height: 1.43,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) => _save(),
              style: AppText.display(
                size: 24,
                weight: FontWeight.w700,
                height: 1.333,
              ),
              decoration: InputDecoration(
                suffixText: _unit,
                suffixStyle: AppText.body(
                  size: 16,
                  color: AppColors.whiteA(0.55),
                  height: 1.5,
                ),
                filled: true,
                fillColor: AppColors.whiteA(0.06),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.whiteA(0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.whiteA(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.cyanA(0.60)),
                ),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              ErrorBox(_error!),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _saving ? null : _save,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.cyan, AppColors.teal],
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Guardar',
                        style: AppText.body(
                          size: 16,
                          weight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas privadas
// ═══════════════════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final StatKpi kpi;

  @override
  Widget build(BuildContext context) {
    final Color pillBackground;
    final Color pillColor;
    switch (kpi.up) {
      case true:
        pillBackground = const Color.fromRGBO(52, 211, 153, 0.15);
        pillColor = AppColors.green;
      case false:
        pillBackground = const Color.fromRGBO(6, 182, 212, 0.15);
        pillColor = AppColors.cyanText;
      case null:
        pillBackground = AppColors.whiteA(0.08);
        pillColor = AppColors.whiteA(0.55);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteA(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteA(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kpi.color.withAlpha(0x22),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(kpi.icon, size: 16, color: kpi.color),
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pillBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    kpi.delta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: pillColor,
                      height: 1.333,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            kpi.value,
            style: AppText.display(
              size: 24,
              weight: FontWeight.w700,
              color: kpi.color,
              height: 1.333,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi.label,
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.45),
              height: 1.333,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.cyanA(0.22) : AppColors.whiteA(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.cyanA(0.40) : AppColors.whiteA(0.10),
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: AppText.body(
              size: 14,
              weight: FontWeight.w600,
              color: selected ? AppColors.cyanText : AppColors.whiteA(0.5),
              height: 1.43,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
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
            size: 16,
            weight: FontWeight.w700,
            color: color,
            height: 1.5,
          ),
        ),
        Text(
          label,
          style: AppText.body(
            size: 12,
            color: AppColors.whiteA(0.40),
            height: 1.333,
          ),
        ),
      ],
    );
  }
}

class _CircumferenceRow extends StatelessWidget {
  const _CircumferenceRow({required this.stat, required this.index});

  final CircumferenceStat stat;
  final int index;

  static Color get _emerald400 => AppColors.green;
  static Color get _red400 => AppColors.red;

  @override
  Widget build(BuildContext context) {
    final String diffText = !stat.hasPrev
        ? 'Primera medición'
        : stat.isNeutral
            ? 'Sin cambios'
            : '${formatSigned(stat.diff)} ${stat.unit}';
    final Color diffColor = stat.isNeutral
        ? AppColors.whiteA(0.50)
        : stat.isGood
            ? _emerald400
            : _red400;

    final Duration delay = Duration(milliseconds: index * 70);
    final Duration total = delay + const Duration(milliseconds: 300);

    // Entrada desde la izquierda (x: -10 -> 0), escalonada por fila.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1.0,
        curve: Curves.easeOut,
      ),
      builder: (BuildContext context, double v, Widget? child) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(offset: Offset(-10 * (1 - v), 0), child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                stat.part,
                style: AppText.body(
                  size: 14,
                  color: AppColors.whiteA(0.75),
                  height: 1.43,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    diffText,
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: diffColor,
                      height: 1.333,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${formatStat(stat.current)} ${stat.unit}',
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.43,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedProgressBar(
            value: stat.fraction,
            height: 6,
            delay: delay,
            duration: const Duration(milliseconds: 600),
            gradient: LinearGradient(
              colors: stat.isGood
                  ? <Color>[AppColors.cyan, _emerald400]
                  : const <Color>[AppColors.teal, AppColors.cyan],
            ),
          ),
        ],
      ),
    );
  }
}