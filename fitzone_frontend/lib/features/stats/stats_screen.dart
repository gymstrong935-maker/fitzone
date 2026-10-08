import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../home/widgets/home_card.dart';
import 'data/stats_data.dart';
import 'widgets/stats_charts.dart';

enum StatsTab { weight, activity, body }

/// Pantalla "Estadísticas" (pestaña de la barra inferior).
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const Color _cyan400 = Color(0xFF22D3EE);
  static const Color _teal400 = Color(0xFF2DD4BF);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _purple400 = Color(0xFFC084FC);
  static const Color _emerald400 = Color(0xFF34D399);

  StatsTab _tab = StatsTab.weight;

  @override
  Widget build(BuildContext context) {
    final double top = 24 + MediaQuery.paddingOf(context).top;
    final double bottom = 96 + MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
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
                _buildKpiGrid(),
                const SizedBox(height: 16),
                _buildTabs(),
                const SizedBox(height: 16),
                _buildPanel(),
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
  Widget _buildKpiGrid() {
    Widget cell(int i) {
      return FadeSlideIn(
        delay: Duration(milliseconds: i * 60),
        duration: const Duration(milliseconds: 400),
        offsetY: 12,
        child: _KpiCard(kpi: kStatKpis[i]),
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < kStatKpis.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: cell(i)),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < kStatKpis.length ? cell(i + 1) : const SizedBox(),
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
  Widget _buildPanel() {
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
        StatsTab.weight => _buildWeightPanel(),
        StatsTab.activity => _buildActivityPanel(),
        StatsTab.body => _buildBodyPanel(),
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
        Column(
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
  Widget _buildWeightPanel() {
    return HomeCard(
      key: const ValueKey<String>('panel-weight'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panelHeader(
            title: 'Peso Corporal',
            subtitle: 'Últimas 6 semanas',
            icon: Icons.trending_down_rounded,
            trailing: '-2 kg',
            color: _cyan400,
          ),
          const SizedBox(height: 16),
          const WeightAreaChart(data: kWeightData),
        ],
      ),
    );
  }

  // ── Pestaña: Actividad ────────────────────────────────────────────────────
  Widget _buildActivityPanel() {
    return HomeCard(
      key: const ValueKey<String>('panel-activity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panelHeader(
            title: 'Tiempo de Entrenamiento',
            subtitle: 'Esta semana · minutos',
            icon: Icons.monitor_heart_outlined,
            trailing: '240 min',
            color: _teal400,
          ),
          const SizedBox(height: 16),
          const ActivityBarChart(data: kActivityData),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.whiteA(0.07))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const <Widget>[
                _SummaryChip(value: '5', label: 'sesiones', color: _cyan400),
                _SummaryChip(value: '240', label: 'minutos', color: _teal400),
                _SummaryChip(value: '1920', label: 'kcal', color: _orange400),
                _SummaryChip(
                  value: '71%',
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
  Widget _buildBodyPanel() {
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
            'vs. medición anterior',
            style: AppText.body(
              size: 12,
              color: AppColors.whiteA(0.40),
              height: 1.333,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < kCircumferences.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 12),
            _CircumferenceRow(stat: kCircumferences[i], index: i),
          ],
        ],
      ),
    );
  }

  // ── Banner de racha ───────────────────────────────────────────────────────
  Widget _buildStreakBanner() {
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
                  'Racha de 7 días',
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Llevas 7 días seguidos entrenando. ¡Increíble!',
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
            '7',
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
        pillColor = const Color(0xFF34D399);
      case false:
        pillBackground = const Color.fromRGBO(6, 182, 212, 0.15);
        pillColor = const Color(0xFF06B6D4);
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
              color: selected ? AppColors.cyan : AppColors.whiteA(0.5),
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

  static const Color _emerald400 = Color(0xFF34D399);
  static const Color _red400 = Color(0xFFF87171);

  @override
  Widget build(BuildContext context) {
    final double diff = stat.diff;
    final String diffText =
        '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} ${stat.unit}';

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
                      color: stat.isGood ? _emerald400 : _red400,
                      height: 1.333,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${formatStat(stat.current)} ${stat.unit}',
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white,
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
                  ? const <Color>[AppColors.cyan, _emerald400]
                  : const <Color>[AppColors.teal, AppColors.cyan],
            ),
          ),
        ],
      ),
    );
  }
}